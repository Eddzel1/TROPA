import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/powersync_schema.dart';
import '../core/ph_time.dart';

/// Offline copy of the COMELEC voters registry for [snapshotVoterLgus].
///
/// The registry is reference data that doesn't change, and ~200k rows would cost far more PowerSync
/// "data synced" than the free plan allows. Instead an admin publishes it once as a gzip file in
/// Supabase Storage (~3–6 MB), and each device downloads and installs it into the local-only
/// `voters` table. Publishing again bumps the manifest version and devices reinstall on next start.

const voterSnapshotBucket = 'voter-snapshots';
const _manifestPath = 'manifest.json';

/// Columns stored in each snapshot row, in order. Remote names (`PC`, `HHL`) map to these.
const voterSnapshotColumns = [
  'id', 'lastname', 'firstname', 'middlename', 'ext', 'purok', 'brgy', 'lgu', 'status', 'pc', 'hhl', 'precinct',
];
const _remoteSelect = 'id,lastname,firstname,middlename,ext,purok,brgy,lgu,status,PC,HHL,precinct';
const _insertBatchSize = 2000;

enum VoterSnapshotPhase { notInstalled, downloading, installing, ready, error }

class VoterSnapshotStatus {
  final VoterSnapshotPhase phase;

  /// 0–1 while installing.
  final double? progress;
  final int? count;
  final String? version;
  final String? error;

  const VoterSnapshotStatus(this.phase, {this.progress, this.count, this.version, this.error});

  bool get isInstalled => count != null;
}

/// Current install state, for the Tropa Finder status line.
final voterSnapshotStatus = ValueNotifier(const VoterSnapshotStatus(VoterSnapshotPhase.notInstalled));
final voterSnapshotStatusProvider = ChangeNotifierProvider((ref) => voterSnapshotStatus);

/// Turns raw `voters` rows into the gzip-compressed snapshot payload: a JSON array of arrays in
/// [voterSnapshotColumns] order, with blank and literal "NULL" values stored as null.
Uint8List encodeVoterSnapshot(List<Map<String, dynamic>> rows) {
  Object? clean(Object? v) {
    if (v is String) {
      final t = v.trim();
      return (t.isEmpty || t.toUpperCase() == 'NULL') ? null : t;
    }
    return v;
  }

  final lowerRows = [for (final r in rows) {for (final e in r.entries) e.key.toLowerCase(): e.value}];
  final table = [for (final r in lowerRows) [for (final c in voterSnapshotColumns) clean(r[c])]];
  return const GZipEncoder().encodeBytes(utf8.encode(jsonEncode(table)), level: 9);
}

/// Inverse of [encodeVoterSnapshot].
List<List<Object?>> decodeVoterSnapshot(Uint8List gz) {
  final table = jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(gz))) as List;
  return [for (final row in table) List<Object?>.from(row as List)];
}

/// Reads the voters of [snapshotVoterLgus] from Supabase and publishes them as a new snapshot.
/// Returns the number of voters published. Requires the admin upload policy on the bucket.
Future<int> publishVoterSnapshot(SupabaseClient client, {void Function(String message)? onProgress}) async {
  const pageSize = 1000;
  final rows = <Map<String, dynamic>>[];
  for (var from = 0;; from += pageSize) {
    final page = await client
        .from('voters')
        .select(_remoteSelect)
        .inFilter('lgu', snapshotVoterLgus.toList())
        .order('id')
        .range(from, from + pageSize - 1);
    rows.addAll(List<Map<String, dynamic>>.from(page));
    onProgress?.call('Reading voters… ${rows.length}');
    if (page.length < pageSize) break;
  }

  onProgress?.call('Compressing ${rows.length} voters…');
  final bytes = await compute(encodeVoterSnapshot, rows);

  final storage = client.storage.from(voterSnapshotBucket);
  final previous = await _fetchManifest(client);
  final version = toPhIso(phNow());
  final path = 'voters-${version.replaceAll(RegExp(r'[^0-9A-Za-z]'), '')}.json.gz';

  onProgress?.call('Uploading ${(bytes.length / 1e6).toStringAsFixed(1)} MB…');
  await storage.uploadBinary(path, bytes,
      fileOptions: const FileOptions(contentType: 'application/gzip', upsert: true));
  // The manifest goes last so devices never see a version whose file isn't uploaded yet.
  final manifest = {
    'version': version,
    'path': path,
    'count': rows.length,
    'lgus': snapshotVoterLgus.toList(),
    'columns': voterSnapshotColumns,
  };
  await storage.uploadBinary(_manifestPath, utf8.encode(jsonEncode(manifest)),
      fileOptions: const FileOptions(contentType: 'application/json', upsert: true, cacheControl: '60'));

  final oldPath = previous?['path'];
  if (oldPath is String && oldPath != path) {
    try {
      await storage.remove([oldPath]);
    } catch (_) {}
  }
  return rows.length;
}

/// The published manifest, or null if offline or nothing has been published yet.
Future<Map<String, dynamic>?> fetchVoterSnapshotManifest(SupabaseClient client) => _fetchManifest(client);

Future<Map<String, dynamic>?> _fetchManifest(SupabaseClient client) async {
  try {
    final bytes = await client.storage.from(voterSnapshotBucket).download(_manifestPath);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

bool _installing = false;

/// Installs the published snapshot if this device doesn't have that version yet. Safe to call at
/// every startup: offline or with nothing published it just keeps what is installed.
Future<void> ensureVoterSnapshot(PowerSyncDatabase db, SupabaseClient client) async {
  if (_installing) return;
  _installing = true;
  try {
    final installed = await db.getOptional("SELECT version, count FROM voter_snapshot_info WHERE id = 'current'");
    final installedStatus = installed == null
        ? const VoterSnapshotStatus(VoterSnapshotPhase.notInstalled)
        : VoterSnapshotStatus(VoterSnapshotPhase.ready,
            count: installed['count'] as int?, version: installed['version'] as String?);
    voterSnapshotStatus.value = installedStatus;

    final manifest = await _fetchManifest(client);
    if (manifest == null || manifest['version'] == installed?['version']) return;

    voterSnapshotStatus.value = VoterSnapshotStatus(VoterSnapshotPhase.downloading,
        count: installedStatus.count, version: installedStatus.version);
    final bytes = await client.storage.from(voterSnapshotBucket).download(manifest['path'] as String);
    final rows = await compute(decodeVoterSnapshot, bytes);

    final version = manifest['version'] as String;
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM voters');
      final insert = 'INSERT INTO voters (${voterSnapshotColumns.join(', ')}) '
          'VALUES (${List.filled(voterSnapshotColumns.length, '?').join(', ')})';
      for (var i = 0; i < rows.length; i += _insertBatchSize) {
        final batch = rows.sublist(i, i + _insertBatchSize > rows.length ? rows.length : i + _insertBatchSize);
        // `id` is text locally, matching voter_flags.voter_id.
        await tx.executeBatch(insert, [for (final r in batch) [r.first?.toString(), ...r.skip(1)]]);
        voterSnapshotStatus.value = VoterSnapshotStatus(VoterSnapshotPhase.installing, progress: (i + batch.length) / rows.length);
      }
      await tx.execute("DELETE FROM voter_snapshot_info WHERE id = 'current'");
      await tx.execute(
        "INSERT INTO voter_snapshot_info (id, version, count, installed_at) VALUES ('current', ?, ?, ?)",
        [version, rows.length, toPhIso(phNow())],
      );
    });
    voterSnapshotStatus.value = VoterSnapshotStatus(VoterSnapshotPhase.ready, count: rows.length, version: version);
  } catch (e) {
    debugPrint('Voter snapshot install failed: $e');
    final previous = voterSnapshotStatus.value;
    voterSnapshotStatus.value = VoterSnapshotStatus(VoterSnapshotPhase.error,
        count: previous.count, version: previous.version, error: e.toString());
  } finally {
    _installing = false;
  }
}
