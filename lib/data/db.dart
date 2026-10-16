import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/env.dart';
import '../services/device_seed.dart';
import '../services/offline_auth.dart';
import '../services/voter_snapshot.dart';
import 'powersync_schema.dart';
import 'supabase_connector.dart';

/// The local database every read and write goes through. Opened in `main()` via [openLocalDatabase].
/// Replaced (not just modified) when a starter database is installed; see [dbGeneration].
late PowerSyncDatabase localDb;

/// File path of [localDb].
late String localDbPath;

/// Bumped when [localDb] is replaced by a starter database. `main.dart` keys the ProviderScope on it,
/// so every provider and notifier is rebuilt against the new database.
final dbGeneration = ValueNotifier(0);

final localDbProvider = Provider<PowerSyncDatabase>((ref) => localDb);

/// Live sync state (connected, uploading, downloading, last synced).
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final db = ref.watch(localDbProvider);
  return db.statusStream;
});

enum SyncState {
  /// POWERSYNC_URL not configured: data stays on this device.
  localOnly,

  /// No connection to the sync service; changes are queued locally.
  offline,

  /// Connected and uploading or downloading.
  syncing,

  /// Connected and up to date.
  synced;

  bool get isOnline => this == syncing || this == synced;
}

/// Connection state shown in the header, sidebar and dashboard badges.
final syncStateProvider = Provider<SyncState>((ref) {
  if (Env.powersyncUrl.isEmpty) return SyncState.localOnly;
  final status = ref.watch(syncStatusProvider).value;
  if (status == null || !status.connected) return SyncState.offline;
  if (status.uploading || status.downloading) return SyncState.syncing;
  return SyncState.synced;
});

/// Number of local changes waiting to be uploaded to Supabase.
final pendingUploadsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(localDbProvider);
  return db.watch('SELECT COUNT(*) AS n FROM ps_crud').map((rows) => rows.first['n'] as int);
});

/// A local change waiting in the upload queue (one row of PowerSync's `ps_crud` table).
typedef PendingUpload = ({int seq, String op, String table, String rowId, Map<String, dynamic> data});

/// The local changes waiting to be uploaded to Supabase, oldest first. Updates live as they upload.
final pendingUploadEntriesProvider = StreamProvider<List<PendingUpload>>((ref) {
  final db = ref.watch(localDbProvider);
  return db.watch('SELECT id, data FROM ps_crud ORDER BY id').map((rows) => [
        for (final row in rows)
          if (jsonDecode(row['data'] as String) case final Map<String, dynamic> d)
            (
              seq: row['id'] as int,
              op: d['op'] as String? ?? '?',
              table: d['type'] as String? ?? '?',
              rowId: d['id'] as String? ?? '',
              data: (d['data'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
      ]);
});

/// Emits whenever any of the comma-separated [tables] change, from a local write or an incoming sync.
/// `ref.watch` it inside a provider to re-run that provider on change.
final tableChangesProvider = StreamProvider.family<void, String>((ref, tables) {
  final db = ref.watch(localDbProvider);
  return db.onChange(tables.split(','), triggerImmediately: false);
});

/// Opens the local database and resumes syncing if a session was saved.
Future<void> openLocalDatabase() async {
  localDbPath = kIsWeb ? 'tropa.db' : p.join((await getApplicationSupportDirectory()).path, 'tropa.db');
  localDb = PowerSyncDatabase(schema: schema, path: localDbPath);
  await localDb.initialize();

  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession;
  // Sync even while the app is locked, so queued changes keep uploading. Not awaited: on a fresh
  // database this may download a starter database, and the app shouldn't wait on that to open.
  if (session != null) useLocalDbFor(session.user.id).ignore();

  auth.onAuthStateChange.listen((data) {
    // The session was ended (explicitly or revoked server-side). Keep the local data for offline
    // use; it is only wiped when a different user signs in (see [useLocalDbFor]).
    if (data.event == AuthChangeEvent.signedOut) localDb.disconnect().ignore();
  });
}

/// Points the local database at [userId]'s data and starts syncing. If another user's data is on
/// this device it is wiped first, so users never see each other's local copy.
Future<void> useLocalDbFor(String userId) async {
  final owner = await OfflineAuth.localDbOwner();
  if (owner != null && owner != userId) await localDb.disconnectAndClear();
  await OfflineAuth.setLocalDbOwner(userId);
  // A fresh device starts from the published starter database instead of a full PowerSync
  // download (no-op otherwise, and falls back to a full sync on any problem).
  await installDeviceSeed(force: false);
  _connect();
  // Install or update the offline voter list in the background (no-op when offline or current).
  ensureVoterSnapshot(localDb, Supabase.instance.client).ignore();
}

/// Number of local changes not yet uploaded to Supabase.
Future<int> pendingUploadCount() async =>
    (await localDb.get('SELECT COUNT(*) AS n FROM ps_crud'))['n'] as int;

void _connect() {
  if (Env.powersyncUrl.isEmpty) {
    debugPrint('POWERSYNC_URL is not set; running on the local database without sync.');
    return;
  }
  localDb.connect(connector: SupabaseConnector()).ignore();
}
