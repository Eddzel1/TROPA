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

    // Re-check right before swapping: the app may have been used while this downloaded.
    if (await pendingUploadCount() > 0 || (!force && !await isFreshLocalDb())) return false;

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
      final storage = await sqlite.connectToRecommended(localDbPath, onlyOpenVfs: true);
      try {
        await storage.database.fileSystem.writeFile(FileType.journal, Uint8List(0));
        await storage.database.fileSystem.writeFile(FileType.database, bytes);
        await storage.database.fileSystem.flush();
        replaced = true;
      } finally {
        await storage.database.dispose();
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
