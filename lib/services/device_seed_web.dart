import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite_async/sqlite3_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../data/db.dart';
import 'device_seed.dart';

/// Browsers install the starter database too: the file is written straight into the browser
/// storage PowerSync uses (OPFS or IndexedDB), before PowerSync opens it.
const deviceSeedSupported = true;

Future<int> publishDeviceSeed(PowerSyncDatabase db, SupabaseClient client, {void Function(String)? onProgress}) =>
    throw UnsupportedError('Publishing the starter database needs the desktop app.');

/// Gunzips with the browser's native DecompressionStream (much faster than decoding in Dart).
Future<Uint8List> _gunzip(Uint8List gz) async {
  final decompressor = web.DecompressionStream('gzip');
  final stream = web.Blob([gz.toJS].toJS).stream().pipeThrough(
        web.ReadableWritablePair(readable: decompressor.readable, writable: decompressor.writable),
      );
  final buffer = await web.Response(stream).arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

/// The storage holding PowerSync's existing `tropa.db`, so the starter file replaces that one.
///
/// PowerSync opens its (empty) database at app start, so on a new browser exactly one exists.
/// Letting the browser "recommend" a storage can pick a different one (OPFS while PowerSync uses
/// IndexedDB), and PowerSync would never see the file. If an earlier attempt left copies in
/// several storages, IndexedDB is kept (where PowerSync has been observed to live) and the other
/// copies are deleted so the next open is unambiguous.
Future<DatabaseImplementation?> _powerSyncStorage(WebSqlite sqlite) async {
  final features = await sqlite.runFeatureDetection(databaseName: localDbPath);
  debugPrint('Starter database: browser storage $features');
  final existing = {for (final (storage, name) in features.existingDatabases) if (name == localDbPath) storage};
  if (existing.isEmpty) return null;

  final target = existing.contains(StorageMode.indexedDb) ? StorageMode.indexedDb : existing.first;
  for (final other in existing.where((s) => s != target)) {
    try {
      await sqlite.deleteDatabase(name: localDbPath, storage: other);
      debugPrint('Starter database: removed a stray copy in ${other.name} storage.');
    } catch (e) {
      debugPrint('Starter database: could not remove the copy in ${other.name} storage: $e');
    }
  }

  final candidates = features.availableImplementations.where((i) => i.storage == target).toList()
    // Prefer the shared worker, which is how PowerSync opens IndexedDB databases across tabs.
    ..sort((a, b) => (a.access == AccessMode.throughSharedWorker ? 0 : 1) - (b.access == AccessMode.throughSharedWorker ? 0 : 1));
  return candidates.isEmpty ? null : candidates.first;
}

bool _installing = false;

/// Browser version of the desktop install: same checks, then the downloaded file replaces the
/// database inside browser storage. Another open TROPA tab could hold the database during the
/// swap, so the Settings button asks to close other tabs first.
Future<bool> installDeviceSeed({required bool force}) async {
  if (_installing) return false;
  _installing = true;
  try {
    final manifest = await seedManifestToInstall(force: force);
    if (manifest == null) return false;

    final gz = BytesBuilder(copy: false);
    await downloadSeedParts(manifest, gz.add);

    deviceSeedProgress.value = 'Setting up this device: unpacking starter data…';
    final bytes = await _gunzip(gz.takeBytes());

    debugPrint('Starter database: unpacked ${seedMb(bytes.length)} MB.');

    // Re-check right before swapping: the app may have been used while this downloaded.
    if (await pendingUploadCount() > 0 || (!force && !await isFreshLocalDb())) {
      debugPrint('Starter database: skipped, this device changed while downloading.');
      return false;
    }

    deviceSeedProgress.value = 'Setting up this device: installing starter data…';
    await localDb.disconnect();
    await localDb.close();
    var replaced = false;
    try {
      // Same worker, wasm and storage selection as PowerSync's web open factory, but only the
      // virtual file system is opened, so the database file can be replaced.
      final sqlite = WebSqlite.open(
        worker: Uri.parse('powersync_db.worker.js'),
        wasmModule: Uri.parse('sqlite3.wasm'),
      );
      final implementation = await _powerSyncStorage(sqlite);
      debugPrint('Starter database: writing into ${implementation?.name ?? 'recommended'} storage.');
      final database = implementation == null
          ? (await sqlite.connectToRecommended(localDbPath, onlyOpenVfs: true)).database
          : await sqlite.connect(localDbPath, implementation, onlyOpenVfs: true);
      await database.fileSystem.writeFile(FileType.journal, Uint8List(0));
      await database.fileSystem.writeFile(FileType.database, bytes);
      await database.fileSystem.flush();
      replaced = true;
      try {
        await database.dispose();
      } catch (_) {
        // sqlite3_web 0.4.1 throws "Null check operator used on a null value" when closing a
        // storage-only (onlyOpenVfs) connection, because no database was opened on it. The file is
        // already written and flushed, so this is safe to ignore.
      }
    } finally {
      await reopenLocalDb(replaced: replaced);
    }
    return true;
  } catch (e) {
    debugPrint('Starter database install failed: $e');
    if (force) rethrow;
    return false;
  } finally {
    deviceSeedProgress.value = null;
    _installing = false;
  }
}
