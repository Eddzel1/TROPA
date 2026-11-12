import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/env.dart';
import '../core/ph_time.dart';
import 'powersync_schema.dart';

/// Postgres error classes that will never succeed on retry:
/// 22 = data exception, 23 = integrity constraint violation, 42501 = insufficient privilege (RLS),
/// PGRST204 = column does not exist in the table.
final _fatalPostgresCodes = [RegExp(r'^22...$'), RegExp(r'^23...$'), RegExp(r'^42501$'), RegExp(r'^PGRST204$')];

/// Hands Supabase Auth tokens to PowerSync and replays queued local writes to Supabase.
/// Conflict policy is last-write-wins: whichever upload reaches Supabase last overwrites the row.
class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _client.auth.currentSession;
    if (session == null || Env.powersyncUrl.isEmpty) return null;
    return PowerSyncCredentials(
      endpoint: Env.powersyncUrl,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  void invalidateCredentials() {
    // Expired token: refresh it so the next fetchCredentials gets a fresh one.
    _client.auth.refreshSession().ignore();
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final tx = await database.getNextCrudTransaction();
    if (tx == null) return;

    CrudEntry? lastOp;
    try {
      // Runs of alike changes go up as one request (e.g. a barangay-wide membership month is
      // thousands of identical PATCHes). Sent one by one, a single failure late in a large
      // transaction restarted it from the top and held back everything queued behind it.
      final ops = tx.crud;
      for (var i = 0; i < ops.length;) {
        final op = lastOp = ops[i];
        var end = i + 1;
        while (end < ops.length && end - i < _batchSize && _batchable(op, ops[end])) {
          end++;
        }
        final batch = ops.sublist(i, end);
        final ids = [for (final o in batch) o.id];
        final table = _client.from(op.table);
        switch (op.op) {
          case UpdateType.put:
            await table.upsert([for (final o in batch) {..._toRemote(o.table, o.opData ?? {}), 'id': o.id}]);
          case UpdateType.patch:
            // PATCH only carries the changed columns, so concurrent edits to different fields both survive.
            final changed = await table.update(_toRemote(op.table, op.opData ?? {})).inFilter('id', ids).select('id');
            await _checkApplied(database, batch, changed, 'Supabase did not save this edit');
          case UpdateType.delete:
            final deleted = await table.delete().inFilter('id', ids).select('id');
            await _checkApplied(database, batch, deleted, 'Supabase did not delete this record');
        }
        i = end;
      }
      await tx.complete();
    } on PostgrestException catch (e) {
      if (e.code != null && _fatalPostgresCodes.any((re) => re.hasMatch(e.code!))) {
        // Retrying would block the queue forever; drop the transaction and keep going, but record
        // why, so the refusal shows in the sync pill instead of the change quietly coming undone.
        debugPrint('Discarding unsyncable change $lastOp: ${e.message}');
        if (lastOp != null) {
          await _recordRejection(database, lastOp,
              code: e.code ?? '', message: [e.message, e.details, e.hint].whereType<Object>().join(' · '),
              changeCount: tx.crud.length);
        }
        await tx.complete();
      } else {
        rethrow;
      }
    }
  }

  /// Row-level security makes Supabase skip rows it won't let this user change, without an error.
  /// [returned] are the rows the request did change; any other row of [batch] that still exists on
  /// the server was refused, so it is recorded (rows already gone elsewhere are fine).
  Future<void> _checkApplied(
      PowerSyncDatabase database, List<CrudEntry> batch, List<Map<String, dynamic>> returned, String message) async {
    final done = {for (final r in returned) r['id'].toString().toLowerCase()};
    final missing = [for (final o in batch) if (!done.contains(o.id.toLowerCase())) o];
    if (missing.isEmpty) return;
    final still = await _client.from(batch.first.table).select('id').inFilter('id', [for (final o in missing) o.id]);
    final kept = {for (final r in still) r['id'].toString().toLowerCase()};
    for (final o in missing.where((o) => kept.contains(o.id.toLowerCase()))) {
      await _recordRejection(database, o,
          code: 'RLS', message: '$message. You may not have permission for it.', changeCount: 1);
    }
  }

  Future<void> _recordRejection(PowerSyncDatabase database, CrudEntry op,
      {required String code, required String message, required int changeCount}) async {
    try {
      await database.execute(
        'INSERT INTO upload_rejections (id, table_name, op, row_id, code, message, data, change_count, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          const Uuid().v4(),
          op.table,
          op.op.toJson(),
          op.id,
          code,
          message,
          op.opData == null ? null : jsonEncode(op.opData),
          changeCount,
          toPhIso(phNow()),
        ],
      );
    } catch (e) {
      debugPrint('Could not record the refused change: $e');
    }
  }

  /// Most rows per request; keeps `id=in.(…)` URLs short.
  static const _batchSize = 100;

  /// Whether [b] can go up in the same request as [a]: same table and operation, and for a PATCH
  /// the same changes. A bulk PUT needs the same columns, or PostgREST would null the missing ones.
  static bool _batchable(CrudEntry a, CrudEntry b) {
    if (a.table != b.table || a.op != b.op) return false;
    return switch (a.op) {
      UpdateType.put => setEquals((a.opData ?? const {}).keys.toSet(), (b.opData ?? const {}).keys.toSet()),
      UpdateType.patch => mapEquals(a.opData, b.opData),
      UpdateType.delete => true,
    };
  }

  /// Converts local SQLite values back to the shapes Postgres expects.
  Map<String, dynamic> _toRemote(String table, Map<String, dynamic> data) {
    final bools = booleanColumns[table] ?? const {};
    final jsons = jsonColumns[table] ?? const {};
    return data.map((key, value) {
      if (bools.contains(key) && value is num) return MapEntry(key, value != 0);
      if (jsons.contains(key) && value is String) {
        try {
          return MapEntry(key, jsonDecode(value));
        } catch (_) {}
      }
      return MapEntry(key, value);
    });
  }
}
