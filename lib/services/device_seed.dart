import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/db.dart';
import '../data/powersync_schema.dart';

export 'device_seed_stub.dart'
    if (dart.library.io) 'device_seed_io.dart'
    if (dart.library.js_interop) 'device_seed_web.dart';

/// Starter database ("pre-seeded SQLite", see docs.powersync.com/client-sdks/advanced/pre-seeded-sqlite).
///
/// An admin's fully synced desktop publishes a compact copy of its local database to Supabase
/// Storage. New devices and browsers download it on first sign-in instead of pulling every member
/// and household through PowerSync, then PowerSync only sends the changes made since the copy was
/// taken. The download counts against Supabase egress, not the PowerSync "data synced" allowance.
///
/// Publishing and the desktop file swap live in device_seed_io.dart; the browser swap (which
/// replaces the file inside browser storage) lives in device_seed_web.dart.

const deviceSeedBucket = 'device-seeds';
const deviceSeedManifestPath = 'manifest.json';

/// Progress text shown while a starter database is downloaded or installed, null when idle.
final deviceSeedProgress = ValueNotifier<String?>(null);

/// The published manifest, or null if offline or nothing has been published yet.
Future<Map<String, dynamic>?> fetchDeviceSeedManifest(SupabaseClient client) async {
  try {
    final bytes = await client.storage.from(deviceSeedBucket).download(deviceSeedManifestPath);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Byte ranges for splitting a file of [length] bytes into parts of at most [partSize].
List<({int start, int end})> seedPartRanges(int length, int partSize) => [
      for (var start = 0; start < length; start += partSize)
        (start: start, end: start + partSize < length ? start + partSize : length),
    ];

String seedMb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(0);

/// The PowerSync core extension version of [db], e.g. `0.4.11/024d5eb0`.
Future<String> powersyncCoreVersion(PowerSyncDatabase db) async =>
    (await db.get('SELECT powersync_rs_version() AS v'))['v'] as String;

/// Whether a device running core [device] can open a starter database written by core [seed]:
/// the same or a newer version (a newer core migrates an older file). Build hashes are ignored.
bool coreVersionAccepts({required String device, required String seed}) {
  List<int>? parse(String v) {
    final parts = v.split('/').first.split('.').map(int.tryParse).toList();
    return parts.contains(null) ? null : parts.cast<int>();
  }

  final d = parse(device), s = parse(seed);
  if (d == null || s == null) return false;
  for (var i = 0; i < d.length || i < s.length; i++) {
    final a = i < d.length ? d[i] : 0, b = i < s.length ? s[i] : 0;
    if (a != b) return a > b;
  }
  return true;
}

/// Whether this device has never synced and has nothing waiting to upload.
Future<bool> isFreshLocalDb() async {
  final row = await localDb.get(
      "SELECT (SELECT COUNT(*) FROM ps_buckets WHERE name <> '\$local') AS buckets, (SELECT COUNT(*) FROM ps_crud) AS crud");
  return row['buckets'] == 0 && row['crud'] == 0;
}

/// Checks whether a starter database should be installed now and returns its manifest, or null.
/// With [force] (the Settings button) the reason is thrown instead of returning null.
Future<Map<String, dynamic>?> seedManifestToInstall({required bool force}) async {
  if (await pendingUploadCount() > 0) {
    if (force) throw StateError('This device has changes that have not uploaded yet. Wait until they sync.');
    return null;
  }
  if (!force && !await isFreshLocalDb()) return null;

  final manifest = await fetchDeviceSeedManifest(Supabase.instance.client);
  if (manifest == null) {
    if (force) throw StateError('No starter database has been published yet (or there is no connection).');
    return null;
  }
  final device = await powersyncCoreVersion(localDb);
  final seed = manifest['core_version']?.toString() ?? '';
  if (!coreVersionAccepts(device: device, seed: seed)) {
    debugPrint('Starter database skipped: published with PowerSync core $seed, this device has $device.');
    if (force) throw StateError('The starter database was published by a newer app version. Update the app.');
    return null;
  }
  return manifest;
}

/// Downloads every part of [manifest] in order, passing each chunk to [onChunk] and reporting
/// progress in [deviceSeedProgress].
Future<void> downloadSeedParts(Map<String, dynamic> manifest, void Function(List<int> chunk) onChunk) async {
  final client = Supabase.instance.client;
  final total = (manifest['bytes'] as num?)?.toInt() ?? 0;
  var received = 0;
  deviceSeedProgress.value = 'Setting up this device: downloading starter data…';
  final httpClient = http.Client();
  try {
    for (final part in (manifest['parts'] as List).cast<String>()) {
      final url = await client.storage.from(deviceSeedBucket).createSignedUrl(part, 3600);
      final res = await httpClient.send(http.Request('GET', Uri.parse(url)));
      if (res.statusCode != 200) throw Exception('Starter data download failed (${res.statusCode})');
      await for (final chunk in res.stream) {
        onChunk(chunk);
        received += chunk.length;
        deviceSeedProgress.value =
            'Setting up this device: downloading starter data ${seedMb(received)} / ${seedMb(total)} MB';
      }
    }
  } finally {
    httpClient.close();
  }
}

/// Opens [localDb] again after it was closed for a swap and rebuilds the app on top of the new
/// instance via [dbGeneration]. When the starter database went in ([replaced]), this device also
/// gets its own PowerSync client id.
Future<void> reopenLocalDb({required bool replaced}) async {
  localDb = PowerSyncDatabase(schema: schema, path: localDbPath);
  await localDb.initialize();
  if (replaced) {
    await localDb.execute("INSERT OR REPLACE INTO ps_kv (key, value) VALUES ('client_id', ?)", [const Uuid().v4()]);
  }
  dbGeneration.value++;
}
