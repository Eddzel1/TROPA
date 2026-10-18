import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/db.dart';
import '../data/powersync_schema.dart';

/// Backup sync: while PowerSync is unreachable but Supabase works, poll Supabase every few minutes
/// for rows that other devices changed or deleted, and write them into the local database.
///
/// Uploads don't need this: the PowerSync client keeps uploading queued edits straight to Supabase
/// even when its download stream is down. Rows pulled here go into PowerSync's internal
/// `ps_data__<table>` tables rather than the views, so no upload is queued for them, while watchers
/// of `<table>` are still notified. When PowerSync reconnects it re-downloads the same rows and
/// takes over again. Needs supabase/migrations/20261016000000_fallback_sync.sql.

typedef FallbackTable = ({String table, String? cursorColumn, String select});

/// Tables kept current during backup sync. Tables without a cursor column are small and re-pulled whole.
const fallbackTables = <FallbackTable>[
  (table: 'households', cursorColumn: 'updated_date', select: '*'),
  (table: 'family_members', cursorColumn: 'updated_date', select: '*'),
  (table: 'dues_payments', cursorColumn: 'updated_date', select: '*'),
  (table: 'users', cursorColumn: 'updated_date', select: '*'),
  (table: 'form_tracking', cursorColumn: 'updated_at', select: '*'),
  (table: 'officers', cursorColumn: 'updated_at', select: '*'),
  (table: 'voter_flags', cursorColumn: 'created_at', select: '*'),
  (table: 'locations', cursorColumn: null, select: '*'),
  (table: 'puroks', cursorColumn: null, select: 'id,location_id,name'),
  (table: 'dues_rates', cursorColumn: null, select: '*'),
];

const _deletesCursorKey = '__deletes';
const _pageSize = 1000;
const _activateAfter = Duration(minutes: 3);
const _pullEvery = Duration(minutes: 3);
const _fullPullEvery = Duration(minutes: 30);

enum FallbackPhase { idle, active, error }

class FallbackState {
  final FallbackPhase phase;
  final DateTime? lastPulledAt;
  const FallbackState(this.phase, {this.lastPulledAt});
}

final fallbackSyncState = ValueNotifier(const FallbackState(FallbackPhase.idle));
final fallbackSyncStateProvider = ChangeNotifierProvider((ref) => fallbackSyncState);

/// Converts a Supabase row to PowerSync's local JSON shape: booleans as 1/0, json/array columns
/// as JSON text. The inverse of `_toRemote` in supabase_connector.dart.
Map<String, dynamic> toLocalRow(String table, Map<String, dynamic> row) {
  final bools = booleanColumns[table] ?? const <String>{};
  final jsons = jsonColumns[table] ?? const <String>{};
  return row.map((key, value) {
    if (bools.contains(key) && value is bool) return MapEntry(key, value ? 1 : 0);
    if (jsons.contains(key) && (value is List || value is Map)) return MapEntry(key, jsonEncode(value));
    return MapEntry(key, value);
  });
}

/// Where polling starts when there is no cursor yet: a little before PowerSync last synced, so
/// nothing changed around that moment is missed (re-applying a row is harmless).
String initialCursor(DateTime lastSyncedAt) =>
    lastSyncedAt.toUtc().subtract(const Duration(minutes: 15)).toIso8601String();

/// Groups deletion-log entries by table, keeping only tables this device stores.
Map<String, List<String>> deletionsByTable(Iterable<Map<String, dynamic>> entries) {
  final known = {for (final t in fallbackTables) t.table};
  final out = <String, List<String>>{};
  for (final e in entries) {
    final table = e['table_name']?.toString();
    final id = e['record_id']?.toString();
    if (table == null || id == null || !known.contains(table)) continue;
    out.putIfAbsent(table, () => []).add(id);
  }
  return out;
}

Timer? _timer;
DateTime? _disconnectedSince;
DateTime? _lastPull;
DateTime? _lastFullPull;
bool _pulling = false;
bool _cursorsCleared = false;

/// Starts watching the PowerSync connection (idempotent). Called whenever local data is set up.
void startFallbackSync() {
  _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => _tick());
}

Future<void> _tick() async {
  final status = localDb.currentStatus;
  if (status.connected) {
    _disconnectedSince = null;
    // Also clears positions left by a backup sync in an earlier app session.
    if (fallbackSyncState.value.phase != FallbackPhase.idle || !_cursorsCleared) await _deactivate();
    return;
  }
  _disconnectedSince ??= DateTime.now();
  final lastSyncedAt = status.lastSyncedAt;
  if (Supabase.instance.client.auth.currentSession == null || lastSyncedAt == null) return;
  if (DateTime.now().difference(_disconnectedSince!) < _activateAfter) return;
  if (_lastPull != null && DateTime.now().difference(_lastPull!) < _pullEvery) return;
  await _pull(lastSyncedAt);
}

Future<void> _deactivate() async {
  _lastPull = null;
  _lastFullPull = null;
  try {
    // PowerSync is back; a later outage starts again from its new last-synced time.
    await localDb.execute('DELETE FROM fallback_cursors');
    _cursorsCleared = true;
  } catch (_) {}
  fallbackSyncState.value = const FallbackState(FallbackPhase.idle);
}

Future<void> _pull(DateTime lastSyncedAt) async {
  if (_pulling) return;
  _pulling = true;
  final client = Supabase.instance.client;
  try {
    final fullPull = _lastFullPull == null || DateTime.now().difference(_lastFullPull!) >= _fullPullEvery;
    for (final t in fallbackTables) {
      if (t.cursorColumn == null) {
        if (fullPull) await _pullAll(client, t);
      } else {
        await _pullChanged(client, t, lastSyncedAt);
      }
    }
    _cursorsCleared = false;
    await _applyDeletions(client, lastSyncedAt);
    if (fullPull) _lastFullPull = DateTime.now();
    _lastPull = DateTime.now();
    fallbackSyncState.value = FallbackState(FallbackPhase.active, lastPulledAt: _lastPull);
  } catch (e) {
    // Usually no internet; try again on the next tick.
    debugPrint('Backup sync pull failed: $e');
    _lastPull = DateTime.now();
    fallbackSyncState.value = FallbackState(FallbackPhase.error, lastPulledAt: fallbackSyncState.value.lastPulledAt);
  } finally {
    _pulling = false;
  }
}

Future<String> _cursor(String key, DateTime lastSyncedAt) async {
  final row = await localDb.getOptional('SELECT cursor FROM fallback_cursors WHERE id = ?', [key]);
  return (row?['cursor'] as String?) ?? initialCursor(lastSyncedAt);
}

Future<void> _saveCursor(String key, String cursor) => localDb.writeTransaction((tx) async {
      await tx.execute('DELETE FROM fallback_cursors WHERE id = ?', [key]);
      await tx.execute('INSERT INTO fallback_cursors (id, cursor) VALUES (?, ?)', [key, cursor]);
    });

/// Ids with local edits still waiting to upload; those rows are never overwritten or deleted here.
Future<Set<String>> _pendingIds(String table) async {
  final rows = await localDb.getAll(
      "SELECT DISTINCT json_extract(data, '\$.id') AS id FROM ps_crud WHERE json_extract(data, '\$.type') = ?",
      [table]);
  return {for (final r in rows) r['id'].toString()};
}

Future<void> _writeRows(String table, List<Map<String, dynamic>> rows) async {
  if (rows.isEmpty) return;
  final pending = await _pendingIds(table);
  await localDb.writeTransaction((tx) async {
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || pending.contains(id)) continue;
      await tx.execute(
          'INSERT OR REPLACE INTO ps_data__$table (id, data) VALUES (?, ?)', [id, jsonEncode(toLocalRow(table, row))]);
    }
  });
}

Future<void> _pullChanged(SupabaseClient client, FallbackTable t, DateTime lastSyncedAt) async {
  final column = t.cursorColumn!;
  // Offsets page through this query's results; the advanced cursor is used on the next pull.
  final cursor = await _cursor(t.table, lastSyncedAt);
  for (var offset = 0;; offset += _pageSize) {
    final page = List<Map<String, dynamic>>.from(await client
        .from(t.table)
        .select(t.select)
        .gte(column, cursor)
        .order(column, ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + _pageSize - 1));
    await _writeRows(t.table, page);
    if (page.isNotEmpty) {
      final newest = page.last[column]?.toString();
      if (newest != null) await _saveCursor(t.table, newest);
    }
    if (page.length < _pageSize) break;
  }
}

Future<void> _pullAll(SupabaseClient client, FallbackTable t) async {
  for (var offset = 0;; offset += _pageSize) {
    final page = List<Map<String, dynamic>>.from(
        await client.from(t.table).select(t.select).order('id', ascending: true).range(offset, offset + _pageSize - 1));
    await _writeRows(t.table, page);
    if (page.length < _pageSize) break;
  }
}

Future<void> _applyDeletions(SupabaseClient client, DateTime lastSyncedAt) async {
  final cursor = await _cursor(_deletesCursorKey, lastSyncedAt);
  for (var offset = 0;; offset += _pageSize) {
    final page = List<Map<String, dynamic>>.from(await client
        .from('deleted_records')
        .select('table_name, record_id, deleted_at')
        .gte('deleted_at', cursor)
        .order('deleted_at', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + _pageSize - 1));
    for (final entry in deletionsByTable(page).entries) {
      final pending = await _pendingIds(entry.key);
      final ids = entry.value.where((id) => !pending.contains(id)).toList();
      if (ids.isEmpty) continue;
      await localDb.writeTransaction((tx) async {
        for (final id in ids) {
          await tx.execute('DELETE FROM ps_data__${entry.key} WHERE id = ?', [id]);
        }
      });
    }
    if (page.isNotEmpty) await _saveCursor(_deletesCursorKey, page.last['deleted_at'].toString());
    if (page.length < _pageSize) break;
  }
}
