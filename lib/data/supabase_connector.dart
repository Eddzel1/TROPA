import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/env.dart';
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
            await table.update(_toRemote(op.table, op.opData ?? {})).inFilter('id', ids);
          case UpdateType.delete:
            await table.delete().inFilter('id', ids);
        }
        i = end;
      }
      await tx.complete();
    } on PostgrestException catch (e) {
      if (e.code != null && _fatalPostgresCodes.any((re) => re.hasMatch(e.code!))) {
        // Retrying would block the queue forever; drop the transaction and keep going.
        debugPrint('Discarding unsyncable change $lastOp: ${e.message}');
        await tx.complete();
      } else {
        rethrow;
      }
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
