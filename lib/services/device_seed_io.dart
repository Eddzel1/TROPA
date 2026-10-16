import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/db.dart';
import '../data/powersync_schema.dart';
import '../core/ph_time.dart';
import 'device_seed.dart';

const deviceSeedSupported = true;

/// Parts stay well under Supabase Storage's per-file upload limit.
const _partSize = 40 * 1024 * 1024;

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(0);

Future<String> _coreVersion(PowerSyncDatabase db) async =>
    (await db.get('SELECT powersync_rs_version() AS v'))['v'] as String;

/// Publishes this device's synced data as the starter database for new devices.
/// This device must be online, fully synced and have no pending uploads. Returns the upload size.
Future<int> publishDeviceSeed(PowerSyncDatabase db, SupabaseClient client, {void Function(String)? onProgress}) async {
  final status = db.currentStatus;
  if (!status.connected || status.hasSynced != true || status.downloading) {
    throw StateError('This device must be online and fully synced before publishing.');
  }
  if (await pendingUploadCount() > 0) {
    throw StateError('This device has changes that have not uploaded yet. Wait until they sync, then try again.');
  }

  final copy = File('$localDbPath.seed-export');
  final gz = File('$localDbPath.seed-export.gz');
  try {
    for (final f in [copy, gz]) {
      if (f.existsSync()) f.deleteSync();
    }

    onProgress?.call('Copying the local database…');
    final buckets = await db.writeLock((tx) async {
      // A consistent copy of the open database (VACUUM can't run inside a transaction, hence writeLock).
      await tx.execute('VACUUM INTO ?', [copy.path]);
      // Strip what belongs to this device only, per PowerSync's pre-seeding guide: its client id,
      // its upload queue and write-checkpoint marker, and the voter list (installed separately).
      await tx.execute('ATTACH DATABASE ? AS seed', [copy.path]);
      try {
        await tx.execute("DELETE FROM seed.ps_kv WHERE key = 'client_id'");
        await tx.execute('DELETE FROM seed.ps_crud');
        await tx.execute("DELETE FROM seed.ps_buckets WHERE name = '\$local'");
        await tx.execute('DELETE FROM seed.ps_data_local__voters');
        await tx.execute('DELETE FROM seed.ps_data_local__voter_snapshot_info');
        await tx.execute('VACUUM seed');
        final rows = await tx.getAll('SELECT name FROM seed.ps_buckets ORDER BY name');
        return [for (final r in rows) r['name'] as String];
      } finally {
        await tx.execute('DETACH DATABASE seed');
      }
    });

    onProgress?.call('Compressing ${_mb(copy.lengthSync())} MB…');
    await copy.openRead().transform(gzip.encoder).pipe(gz.openWrite());
    final size = gz.lengthSync();

    final storage = client.storage.from(deviceSeedBucket);
    final previous = await fetchDeviceSeedManifest(client);
    final version = toPhIso(phNow());
    final folder = 'seed-${version.replaceAll(RegExp(r'[^0-9A-Za-z]'), '')}';
    final ranges = seedPartRanges(size, _partSize);
    final parts = <String>[];
    final raf = await gz.open();
    try {
      for (final (i, r) in ranges.indexed) {
        onProgress?.call('Uploading part ${i + 1} of ${ranges.length} (${_mb(size)} MB total)…');
        await raf.setPosition(r.start);
        final bytes = await raf.read(r.end - r.start);
        final path = '$folder/part-${i.toString().padLeft(3, '0')}';
        await storage.uploadBinary(path, bytes,
            fileOptions: const FileOptions(contentType: 'application/octet-stream', upsert: true));
        parts.add(path);
      }
    } finally {
      await raf.close();
    }

    // The manifest goes last so devices never see a version whose parts aren't all uploaded.
    final manifest = {
      'version': version,
      'parts': parts,
      'bytes': size,
      'buckets': buckets,
      'core_version': await _coreVersion(db),
      'created_at': version,
    };
    await storage.uploadBinary(deviceSeedManifestPath, utf8.encode(jsonEncode(manifest)),
        fileOptions: const FileOptions(contentType: 'application/json', upsert: true, cacheControl: '60'));

    final oldParts = (previous?['parts'] as List?)?.cast<String>() ?? const [];
    if (oldParts.isNotEmpty) {
      try {
        await storage.remove(oldParts);
      } catch (_) {}
    }
    return size;
  } finally {
    for (final f in [copy, gz]) {
      if (f.existsSync()) f.deleteSync();
    }
  }
}

/// Whether this device has never synced and has nothing waiting to upload.
Future<bool> _isFreshLocalDb() async {
  final row = await localDb.get(
      "SELECT (SELECT COUNT(*) FROM ps_buckets WHERE name <> '\$local') AS buckets, (SELECT COUNT(*) FROM ps_crud) AS crud");
  return row['buckets'] == 0 && row['crud'] == 0;
}

bool _installing = false;

/// Downloads the published starter database and swaps it in as the local database.
///
/// Automatic use (`force: false`) only acts on a fresh device and silently returns false when
/// there's nothing to do or anything fails, leaving a normal full sync. The Settings button uses
/// `force: true` to reinstall on any device without pending uploads, and gets errors thrown back.
/// Returns true when the database was replaced; [dbGeneration] then rebuilds the app on top of it.
Future<bool> installDeviceSeed({required bool force}) async {
  if (_installing) return false;
  _installing = true;
  final gz = File('$localDbPath.seed.gz');
  final seed = File('$localDbPath.seed');
  try {
    if (await pendingUploadCount() > 0) {
      if (force) throw StateError('This device has changes that have not uploaded yet. Wait until they sync.');
      return false;
    }
    if (!force && !await _isFreshLocalDb()) return false;

    final client = Supabase.instance.client;
    final manifest = await fetchDeviceSeedManifest(client);
    if (manifest == null) {
      if (force) throw StateError('No starter database has been published yet (or there is no connection).');
      return false;
    }
    if (manifest['core_version'] != await _coreVersion(localDb)) {
      if (force) throw StateError('The starter database was published by a different app version. Publish it again.');
      return false;
    }

    final total = (manifest['bytes'] as num?)?.toInt() ?? 0;
    var received = 0;
    deviceSeedProgress.value = 'Setting up this device: downloading starter data…';
    final sink = gz.openWrite();
    try {
      final httpClient = http.Client();
      try {
        for (final part in (manifest['parts'] as List).cast<String>()) {
          final url = await client.storage.from(deviceSeedBucket).createSignedUrl(part, 3600);
          final res = await httpClient.send(http.Request('GET', Uri.parse(url)));
          if (res.statusCode != 200) throw HttpException('Starter data download failed (${res.statusCode})');
          await for (final chunk in res.stream) {
            sink.add(chunk);
            received += chunk.length;
            deviceSeedProgress.value =
                'Setting up this device: downloading starter data ${_mb(received)} / ${_mb(total)} MB';
          }
        }
      } finally {
        httpClient.close();
      }
    } finally {
      await sink.close();
    }

    deviceSeedProgress.value = 'Setting up this device: unpacking starter data…';
    await gz.openRead().transform(gzip.decoder).pipe(seed.openWrite());

    // Re-check right before swapping: the app may have been used while this downloaded.
    if (await pendingUploadCount() > 0 || (!force && !await _isFreshLocalDb())) return false;

    deviceSeedProgress.value = 'Setting up this device: installing starter data…';
    await localDb.disconnect();
    await localDb.close();
    try {
      for (final suffix in ['', '-wal', '-shm']) {
        final f = File('$localDbPath$suffix');
        if (f.existsSync()) f.deleteSync();
      }
      seed.renameSync(localDbPath);
    } finally {
      // Reopen whatever is in place (the starter database, or an empty one if the swap failed).
      localDb = PowerSyncDatabase(schema: schema, path: localDbPath);
      await localDb.initialize();
    }
    // Every device needs its own PowerSync client id.
    await localDb.execute("INSERT OR REPLACE INTO ps_kv (key, value) VALUES ('client_id', ?)", [const Uuid().v4()]);
    dbGeneration.value++;
    return true;
  } catch (e) {
    debugPrint('Starter database install failed: $e');
    if (force) rethrow;
    return false;
  } finally {
    for (final f in [gz, seed]) {
      if (f.existsSync()) f.deleteSync();
    }
    deviceSeedProgress.value = null;
    _installing = false;
  }
}
