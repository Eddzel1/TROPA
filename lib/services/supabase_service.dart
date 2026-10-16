import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:powersync/sqlite_async.dart' show SqliteWriteContext;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/geo.dart';
import '../data/powersync_schema.dart';
import '../models/models.dart';
import '../core/ph_time.dart';

/// Data access for the app. Reads and writes go to the local PowerSync database, which syncs
/// with Supabase in the background; only auth, storage uploads and the audit log view talk to
/// Supabase directly.
class SupabaseService {
  SupabaseService(this.db);

  final PowerSyncDatabase db;
  final SupabaseClient client = Supabase.instance.client;
  static const uuid = Uuid();

  // Authentication Getters
  User? get currentAuthUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;

  // ==========================================
  // Auto Activity Logger
  // ==========================================
  Future<void> logActivity({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await db.writeTransaction(
        (tx) => _log(tx, action: action, entityType: entityType, entityId: entityId, details: details),
      );
    } catch (_) {
      // Activity logging is designed to fail non-blockingly
    }
  }

  /// Records an activity log row inside the caller's transaction, so the log and the change sync together.
  Future<void> _log(
    SqliteWriteContext tx, {
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    final user = currentAuthUser;
    await _insert(tx, 'activity_logs', {
      'id': uuid.v4(),
      'user_id': user?.id,
      'user_name': user?.email ?? 'System Admin',
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details != null ? jsonEncode(details) : null,
      'created_at': toPhIso(phNow()),
    });
  }

  // ==========================================
  // Local SQL helpers
  // ==========================================
  static String _now() => toPhIso(phNow());

  /// SQLite has no booleans or arrays: store bools as 0/1 and lists/maps as JSON text.
  static Object? _sqlValue(Object? v) {
    if (v is bool) return v ? 1 : 0;
    if (v is List || v is Map) return jsonEncode(v);
    return v;
  }

  /// Escapes LIKE wildcards in user input; pair with `ESCAPE '\'`.
  static String _escapeLike(String v) =>
      v.trim().replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static Future<void> _insert(SqliteWriteContext tx, String table, Map<String, dynamic> row) async {
    final cols = row.keys.toList();
    await tx.execute(
      'INSERT INTO $table (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
      [for (final c in cols) _sqlValue(row[c])],
    );
  }

  static Future<void> _update(SqliteWriteContext tx, String table, String id, Map<String, dynamic> changes) async {
    final cols = changes.keys.where((c) => c != 'id').toList();
    await tx.execute(
      'UPDATE $table SET ${cols.map((c) => '$c = ?').join(', ')} WHERE id = ?',
      [for (final c in cols) _sqlValue(changes[c]), id],
    );
  }

  Future<Map<String, dynamic>?> _getRow(String table, String id) async {
    final row = await db.getOptional('SELECT * FROM $table WHERE id = ?', [id]);
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> _rows(String sql, [List<Object?> params = const []]) async {
    final rs = await db.getAll(sql, params);
    return rs.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static String _whereSql(List<String> where) => where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

  // ==========================================
  // Storage Upload Operations (online only)
  // ==========================================
  Future<String?> uploadStorageFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      // In case bucket is private or storage error, return null safely
      return null;
    }
  }

  Future<String?> uploadProfilePicture({
    required String memberId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final fileName = '$memberId-${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'avatars/$fileName';
    final url = await uploadStorageFile(
      bucket: 'profile-pictures',
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
    if (url != null) {
      await logActivity(
        action: 'UPLOAD_AVATAR',
        entityType: 'FamilyMember',
        entityId: memberId,
        details: {'path': path, 'url': url},
      );
    }
    return url;
  }

  Future<String?> uploadHousePicture({
    required String householdId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final fileName = '$householdId-${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'houses/$fileName';
    final url = await uploadStorageFile(
      bucket: 'house-pictures',
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
    if (url != null) {
      await logActivity(
        action: 'UPLOAD_HOUSE_PIC',
        entityType: 'Household',
        entityId: householdId,
        details: {'path': path, 'url': url},
      );
    }
    return url;
  }

  Future<String?> uploadVoterBlocklist({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = 'blocklists/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    final url = await uploadStorageFile(
      bucket: 'voter_blocklist',
      path: path,
      bytes: bytes,
      contentType: 'text/csv',
    );
    if (url != null) {
      await logActivity(
        action: 'UPLOAD_BLOCKLIST',
        entityType: 'VoterBlocklist',
        details: {'path': path, 'fileName': fileName},
      );
    }
    return url;
  }

  // ==========================================
  // Households CRUD
  // ==========================================
  Future<List<Household>> getHouseholds({
    String? query,
    String? lgu,
    String? barangay,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final where = <String>[];
      final params = <Object?>[];
      if (lgu != null && lgu.isNotEmpty && lgu != 'All') {
        where.add('UPPER(TRIM(lgu)) = ?');
        params.add(lgu.trim().toUpperCase());
      }
      if (barangay != null && barangay.isNotEmpty && barangay != 'All') {
        where.add('UPPER(TRIM(barangay)) = ?');
        params.add(barangay.trim().toUpperCase());
      }
      if (query != null && query.trim().isNotEmpty) {
        where.add(r"household_name LIKE ? ESCAPE '\'");
        params.add('%${_escapeLike(query)}%');
      }
      final rows = await _rows(
        'SELECT * FROM households ${_whereSql(where)} ORDER BY created_date DESC LIMIT ? OFFSET ?',
        [...params, pageSize, page * pageSize],
      );
      return rows.map(Household.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Household?> getHouseholdById(String id) async {
    try {
      final row = await _getRow('households', id);
      return row == null ? null : Household.fromJson(row);
    } catch (e) {
      return null;
    }
  }

  Future<Household> createHousehold(Household item) async {
    await db.writeTransaction((tx) async {
      await _insert(tx, 'households', item.toJson());
      await _log(
        tx,
        action: 'CREATE',
        entityType: 'Household',
        entityId: item.id,
        details: {'household_name': item.householdName, 'barangay': item.barangay},
      );
    });
    return Household.fromJson((await _getRow('households', item.id))!);
  }

  Future<Household> updateHousehold(Household item) async {
    final payload = item.toJson();
    payload['updated_date'] = _now();
    await db.writeTransaction((tx) async {
      await _update(tx, 'households', item.id, payload);
      await _log(
        tx,
        action: 'UPDATE',
        entityType: 'Household',
        entityId: item.id,
        details: {'household_name': item.householdName, 'status': item.status},
      );
    });
    return Household.fromJson((await _getRow('households', item.id))!);
  }

  Future<void> deleteHousehold(String id) async {
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM households WHERE id = ?', [id]);
      await _log(tx, action: 'DELETE', entityType: 'Household', entityId: id);
    });
  }

  // ==========================================
  // Family Members CRUD
  // ==========================================
  Future<List<FamilyMember>> getMembers({
    String? query,
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    String? sector,
    String? listingStatus,
    bool? isCoopMember,
    String? householdId,
    int page = 0,
    int pageSize = 50,
  }) async {
    final result = await getMembersWithCount(
      query: query,
      lastName: lastName,
      firstName: firstName,
      middleName: middleName,
      lgu: lgu,
      barangay: barangay,
      sector: sector,
      listingStatus: listingStatus,
      isCoopMember: isCoopMember,
      householdId: householdId,
      page: page,
      pageSize: pageSize,
    );
    return result.members;
  }

  /// Filtered page of members plus the total number of rows matching the filters.
  Future<({List<FamilyMember> members, int matchCount})> getMembersWithCount({
    String? query,
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    String? sector,
    String? listingStatus,
    bool? isCoopMember,
    String? householdId,
    int page = 0,
    int pageSize = 50,
  }) async {
    bool has(String? v) => v != null && v.trim().isNotEmpty && v != 'All';
    try {
      final where = <String>[];
      final params = <Object?>[];
      void eq(String col, Object? v) {
        where.add('$col = ?');
        params.add(v);
      }

      void startsWith(String col, String v) {
        where.add("$col LIKE ? ESCAPE '\\'");
        params.add('${_escapeLike(v)}%');
      }

      if (has(householdId)) eq('household_id', householdId);
      if (has(lgu)) eq('lgu', lgu);
      if (has(barangay)) eq('barangay', barangay);
      if (has(sector)) {
        // sector holds a comma list ("Student, PWD"); match the whole entry anywhere in it
        where.add("(', ' || sector || ',') LIKE ? ESCAPE '\\'");
        params.add('%, ${_escapeLike(sector!)},%');
      }
      if (has(listingStatus)) eq('listing_status', listingStatus);
      if (isCoopMember != null) eq('is_cooperative_member', isCoopMember ? 1 : 0);
      if (has(lastName)) startsWith('lastname', lastName!);
      if (has(firstName)) startsWith('firstname', firstName!);
      if (has(middleName)) startsWith('middlename', middleName!);
      if (has(query)) {
        final q = '%${_escapeLike(query!)}%';
        where.add(r"(firstname LIKE ? ESCAPE '\' OR lastname LIKE ? ESCAPE '\')");
        params.addAll([q, q]);
      }
      final whereSql = _whereSql(where);
      final rows = await _rows(
        'SELECT * FROM family_members $whereSql ORDER BY lastname, firstname LIMIT ? OFFSET ?',
        [...params, pageSize, page * pageSize],
      );
      final count = await db.get('SELECT COUNT(*) AS n FROM family_members $whereSql', params);
      return (members: rows.map(FamilyMember.fromJson).toList(), matchCount: count['n'] as int);
    } catch (e) {
      return (members: <FamilyMember>[], matchCount: 0);
    }
  }

  Future<int> countAllMembers() async {
    try {
      return (await db.get('SELECT COUNT(*) AS n FROM family_members'))['n'] as int;
    } catch (e) {
      return 0;
    }
  }

  Future<FamilyMember> createMember(FamilyMember member) async {
    await db.writeTransaction((tx) async {
      await _insert(tx, 'family_members', member.toJson());
      await _log(
        tx,
        action: 'CREATE',
        entityType: 'FamilyMember',
        entityId: member.id,
        details: {'name': member.fullName, 'barangay': member.barangay},
      );
    });
    return FamilyMember.fromJson((await _getRow('family_members', member.id))!);
  }

  Future<List<FamilyMember>> createFamilyMembersBulk(List<FamilyMember> members) async {
    if (members.isEmpty) return [];
    await db.writeTransaction((tx) async {
      for (final m in members) {
        await _insert(tx, 'family_members', m.toJson());
      }
      await _log(
        tx,
        action: 'CREATE_BULK',
        entityType: 'FamilyMember',
        details: {
          'count': members.length,
          'household_id': members.first.householdId,
          'barangay': members.first.barangay,
        },
      );
    });
    final ids = members.map((m) => m.id).toList();
    final rows = await _rows(
      'SELECT * FROM family_members WHERE id IN (${List.filled(ids.length, '?').join(', ')})',
      ids,
    );
    return rows.map(FamilyMember.fromJson).toList();
  }

  Future<FamilyMember> updateMember(FamilyMember member) async {
    final payload = member.toJson();
    payload['updated_date'] = _now();
    await db.writeTransaction((tx) async {
      await _update(tx, 'family_members', member.id, payload);
      await _log(
        tx,
        action: 'UPDATE',
        entityType: 'FamilyMember',
        entityId: member.id,
        details: {'name': member.fullName},
      );
    });
    return FamilyMember.fromJson((await _getRow('family_members', member.id))!);
  }

  Future<int> countHouseholdMembers(String householdId) async {
    final row = await db.get('SELECT COUNT(*) AS n FROM family_members WHERE household_id = ?', [householdId]);
    return row['n'] as int;
  }

  /// Moves a member into another household as a regular (non-leader) member, taking on that
  /// household's address. The household they leave is deleted if nobody else is left in it.
  /// Returns whether the old household was deleted.
  Future<bool> transferMember({required String memberId, required String targetHouseholdId}) async {
    var deletedOld = false;
    await db.writeTransaction((tx) async {
      final member = await tx.getOptional('SELECT * FROM family_members WHERE id = ?', [memberId]);
      final target = await tx.getOptional('SELECT * FROM households WHERE id = ?', [targetHouseholdId]);
      if (member == null) throw StateError('Member not found');
      if (target == null) throw StateError('Target household not found');
      final oldId = member['household_id'] as String?;
      if (oldId == targetHouseholdId) throw StateError('Member is already in this household');

      await _update(tx, 'family_members', memberId, {
        'household_id': targetHouseholdId,
        'is_household_leader': false,
        'lgu': target['lgu'],
        'barangay': target['barangay'],
        'purok': target['purok'],
        'purok_id': target['purok_id'],
        'updated_date': _now(),
      });
      await tx.execute('UPDATE dues_payments SET household_id = ? WHERE member_id = ?', [targetHouseholdId, memberId]);

      // Member counts on a household are encoded by hand, so only raise them when the roster outgrows them.
      final targetCount = (await tx.get('SELECT COUNT(*) AS n FROM family_members WHERE household_id = ?', [targetHouseholdId]))['n'] as int;
      await tx.execute(
        'UPDATE households SET total_members = MAX(COALESCE(total_members, 0), ?), '
        'active_members = MAX(COALESCE(active_members, 0), ?), updated_date = ? WHERE id = ?',
        [targetCount, targetCount, _now(), targetHouseholdId],
      );

      if (oldId != null && oldId.isNotEmpty) {
        final left = (await tx.get('SELECT COUNT(*) AS n FROM family_members WHERE household_id = ?', [oldId]))['n'] as int;
        final dues = (await tx.get('SELECT COUNT(*) AS n FROM dues_payments WHERE household_id = ?', [oldId]))['n'] as int;
        if (left == 0 && dues == 0) {
          await tx.execute('DELETE FROM households WHERE id = ?', [oldId]);
          await _log(tx, action: 'DELETE', entityType: 'Household', entityId: oldId, details: {'reason': 'emptied by member transfer'});
          deletedOld = true;
        } else {
          await tx.execute(
            'UPDATE households SET household_leader_id = NULL, updated_date = ? WHERE id = ? AND household_leader_id = ?',
            [_now(), oldId, memberId],
          );
        }
      }

      await _log(
        tx,
        action: 'TRANSFER',
        entityType: 'FamilyMember',
        entityId: memberId,
        details: {
          'name': '${member['lastname']}, ${member['firstname']}',
          'from_household_id': oldId,
          'to_household_id': targetHouseholdId,
          'to_household_name': target['household_name'],
        },
      );
    });
    return deletedOld;
  }

  Future<void> deleteMember(String id) async {
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM family_members WHERE id = ?', [id]);
      await _log(tx, action: 'DELETE', entityType: 'FamilyMember', entityId: id);
    });
  }

  // ==========================================
  // Dues Payments CRUD
  // ==========================================
  Future<List<DuesPayment>> getDuesPayments({
    String? memberId,
    String? householdId,
    String? query,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final where = <String>[];
      final params = <Object?>[];
      if (memberId != null && memberId.isNotEmpty) {
        where.add('member_id = ?');
        params.add(memberId);
      }
      if (householdId != null && householdId.isNotEmpty) {
        where.add('household_id = ?');
        params.add(householdId);
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = '%${_escapeLike(query)}%';
        where.add(r"(payment_month LIKE ? ESCAPE '\' OR reference_number LIKE ? ESCAPE '\')");
        params.addAll([q, q]);
      }
      final rows = await _rows(
        'SELECT * FROM dues_payments ${_whereSql(where)} ORDER BY payment_date DESC LIMIT ? OFFSET ?',
        [...params, pageSize, page * pageSize],
      );
      return rows.map(DuesPayment.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  Future<DuesPayment> createDuesPayment(DuesPayment payment) async {
    await db.writeTransaction((tx) async {
      await _insert(tx, 'dues_payments', payment.toJson());
      await _log(
        tx,
        action: 'CREATE',
        entityType: 'DuesPayment',
        entityId: payment.id,
        details: {'amount': payment.amount, 'month': payment.paymentMonth},
      );
    });
    return DuesPayment.fromJson((await _getRow('dues_payments', payment.id))!);
  }

  Future<void> deleteDuesPayment(String id) async {
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM dues_payments WHERE id = ?', [id]);
      await _log(tx, action: 'DELETE', entityType: 'DuesPayment', entityId: id);
    });
  }

  // ==========================================
  // Form Tracking Batches CRUD
  // ==========================================
  /// [lgu] matches through `locations`, since `form_tracking` only stores the barangay name.
  /// Rows come in submission-date order, newest first unless [oldestFirst].
  Future<List<FormTracking>> getFormBatches({
    String? query,
    String? status,
    String? lgu,
    String? barangay,
    bool oldestFirst = false,
  }) async {
    try {
      final where = <String>[];
      final params = <Object?>[];
      if (status != null && status.isNotEmpty && status != 'All') {
        where.add('status = ?');
        params.add(status);
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = '%${_escapeLike(query)}%';
        where.add(r"(barangay LIKE ? ESCAPE '\' OR purok LIKE ? ESCAPE '\' OR submitted_by LIKE ? ESCAPE '\' OR received_by LIKE ? ESCAPE '\')");
        params.addAll([q, q, q, q]);
      }
      if (lgu != null && lgu.isNotEmpty) {
        where.add("UPPER(TRIM(barangay)) IN (SELECT UPPER(TRIM(barangay)) FROM locations WHERE UPPER(TRIM(lgu)) = ?)");
        params.add(lgu.trim().toUpperCase());
      }
      if (barangay != null && barangay.isNotEmpty) {
        where.add('UPPER(TRIM(barangay)) = ?');
        params.add(barangay.trim().toUpperCase());
      }
      final rows = await _rows(
        'SELECT * FROM form_tracking ${_whereSql(where)} ORDER BY created_at ${oldestFirst ? 'ASC' : 'DESC'}',
        params,
      );
      return rows.map(FormTracking.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createFormBatches(List<FormTracking> batches) async {
    await db.writeTransaction((tx) async {
      for (final batch in batches) {
        await _insert(tx, 'form_tracking', batch.toJson());
        await _log(
          tx,
          action: 'CREATE',
          entityType: 'FormTracking',
          entityId: batch.id,
          details: {'barangay': batch.barangay, 'purok': batch.purok, 'number_of_forms': batch.numberOfForms},
        );
      }
    });
  }

  Future<FormTracking> updateFormBatch(FormTracking batch) async {
    final payload = batch.toJson();
    payload['updated_at'] = _now();
    await db.writeTransaction((tx) async {
      await _update(tx, 'form_tracking', batch.id, payload);
      await _log(
        tx,
        action: 'UPDATE',
        entityType: 'FormTracking',
        entityId: batch.id,
        details: {'status': batch.status, 'number_of_forms': batch.numberOfForms},
      );
    });
    return FormTracking.fromJson((await _getRow('form_tracking', batch.id))!);
  }

  Future<void> deleteFormBatch(String id) async {
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM form_tracking WHERE id = ?', [id]);
      await _log(tx, action: 'DELETE', entityType: 'FormTracking', entityId: id);
    });
  }

  // ==========================================
  // Voters & Verification (Tropa Finder / Registration)
  // ==========================================
  /// WHERE clause shared by the local voter searches: name contains-matches, exact (case-insensitive)
  /// barangay, and LGU.
  ({List<String> where, List<Object?> params}) _voterWhere({
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
  }) {
    bool has(String? v) => v != null && v.trim().isNotEmpty;
    final where = <String>[];
    final params = <Object?>[];
    void contains(String col, String v) {
      where.add("v.$col LIKE ? ESCAPE '\\'");
      params.add('%${_escapeLike(v)}%');
    }

    if (has(lastName)) contains('lastname', lastName!);
    if (has(firstName)) contains('firstname', firstName!);
    if (has(middleName)) contains('middlename', middleName!);
    if (has(barangay) && !_isAllFilter(barangay!)) {
      where.add(r"v.brgy LIKE ? ESCAPE '\'");
      params.add(_escapeLike(barangay));
    }
    if (has(lgu) && !_isAllFilter(lgu!)) {
      where.add('UPPER(v.lgu) = UPPER(?)');
      params.add(lgu.trim());
    }
    return (where: where, params: params);
  }

  static bool _isAllFilter(String v) => v == 'All' || v == 'All Barangays' || v == 'All LGUs';

  /// Local voters joined with their flags; flags are synced separately in `voter_flags`.
  static const _localVoterSelect = 'SELECT v.*, f.voter_id IS NOT NULL AS is_flagged, f.reason AS flag_reason '
      'FROM voters v '
      'LEFT JOIN (SELECT voter_id, MAX(reason) AS reason FROM voter_flags GROUP BY voter_id) f ON f.voter_id = v.id';

  /// Whether to search the installed voter snapshot: it must be installed and cover the requested
  /// LGU (or all LGUs). Otherwise the caller queries Supabase.
  Future<bool> _useLocalVoters(String? lgu) async {
    if (lgu != null && lgu.trim().isNotEmpty && !_isAllFilter(lgu) && !snapshotVoterLgus.contains(lgu.trim().toUpperCase())) {
      return false;
    }
    try {
      return await db.getOptional("SELECT 1 FROM voter_snapshot_info WHERE id = 'current'") != null;
    } catch (_) {
      return false;
    }
  }

  /// Searches the COMELEC voters registry by name (contains match), optionally narrowed by barangay/LGU.
  /// Uses the offline snapshot for its LGUs and Supabase for the rest.
  Future<List<VoterSearchResult>> searchVoterRegistry({
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    int limit = 50,
  }) async {
    bool has(String? v) => v != null && v.trim().isNotEmpty;
    if (!has(lastName) && !has(firstName) && !has(middleName)) {
      return [];
    }
    if (!await _useLocalVoters(lgu)) {
      return _searchVoterRegistryOnline(
          lastName: lastName, firstName: firstName, middleName: middleName, lgu: lgu, barangay: barangay, limit: limit);
    }
    try {
      final w = _voterWhere(lastName: lastName, firstName: firstName, middleName: middleName, lgu: lgu, barangay: barangay);
      final rows = await _rows(
        '$_localVoterSelect ${_whereSql(w.where)} ORDER BY v.lastname, v.firstname LIMIT ?',
        [...w.params, limit],
      );
      return rows.map(VoterSearchResult.fromVoterRow).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VoterSearchResult>> _searchVoterRegistryOnline({
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    int limit = 50,
  }) async {
    bool has(String? v) => v != null && v.trim().isNotEmpty;
    bool isAll(String v) => v == 'All' || v == 'All Barangays' || v == 'All LGUs';

    try {
      var req = client.from('voters').select();
      if (has(lastName)) req = req.ilike('lastname', '%${lastName!.trim()}%');
      if (has(firstName)) req = req.ilike('firstname', '%${firstName!.trim()}%');
      if (has(middleName)) req = req.ilike('middlename', '%${middleName!.trim()}%');
      if (has(barangay) && !isAll(barangay!)) req = req.ilike('brgy', barangay.trim());

      final response = await req
          .order('lastname', ascending: true)
          .order('firstname', ascending: true)
          .limit(limit);
      var results = (response as List).map((row) => VoterSearchResult.fromVoterRow(row as Map<String, dynamic>)).toList();

      // LGU is filtered locally because not every voters import carries an `lgu` column
      if (has(lgu) && !isAll(lgu!)) {
        results = results.where((r) => r.lgu.isEmpty || r.lgu.toUpperCase() == lgu.toUpperCase()).toList();
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Distinct (lgu, barangay) pairs from the `locations` table, used to populate LGU/Barangay filters.
  Future<List<LocationOption>> getLocations() async {
    try {
      final rows = await _rows(
        "SELECT id, UPPER(TRIM(COALESCE(lgu, ''))) AS lgu, UPPER(TRIM(COALESCE(barangay, ''))) AS barangay, latitude, longitude "
        "FROM locations WHERE TRIM(COALESCE(lgu, '')) != '' OR TRIM(COALESCE(barangay, '')) != ''",
      );
      return rows
          .map((r) => (
                id: r['id']?.toString() ?? '',
                lgu: r['lgu'] as String,
                barangay: r['barangay'] as String,
                latitude: (r['latitude'] as num?)?.toDouble(),
                longitude: (r['longitude'] as num?)?.toDouble(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Puroks of one `locations` row (linked by `puroks.location_id`), in natural order (P-2 before P-10).
  /// Reads the local PowerSync copy first and falls back to Supabase when `puroks` isn't synced.
  Future<List<({String id, String name})>> getPuroks(String locationId) async {
    var rows = <Map<String, dynamic>>[];
    try {
      rows = await _rows('SELECT id, name FROM puroks WHERE location_id = ?', [locationId]);
    } catch (_) {}
    if (rows.isEmpty) {
      try {
        final res = await client.from('puroks').select('id, name').eq('location_id', locationId);
        rows = List<Map<String, dynamic>>.from(res);
      } catch (_) {
        return [];
      }
    }
    final puroks = rows
        .map((r) => (id: r['id']?.toString() ?? '', name: r['name']?.toString().trim() ?? ''))
        .where((p) => p.name.isNotEmpty)
        .toList()
      ..sort((a, b) => _naturalCompare(a.name, b.name));
    return puroks;
  }

  /// Compares strings treating digit runs as numbers, so "P-2" < "P-10".
  static int _naturalCompare(String a, String b) {
    final re = RegExp(r'(\d+)|(\D+)');
    final pa = re.allMatches(a.toUpperCase()).map((m) => m.group(0)!).toList();
    final pb = re.allMatches(b.toUpperCase()).map((m) => m.group(0)!).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final na = int.tryParse(pa[i]);
      final nb = int.tryParse(pb[i]);
      final c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  /// Queries the COMELEC voters registry only (never `family_members`). Uses the offline snapshot
  /// for its LGUs and Supabase for the rest.
  Future<List<Voter>> getVoters({
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    bool? flaggedOnly,
  }) async {
    if (!await _useLocalVoters(lgu)) {
      return _getVotersOnline(
          lastName: lastName, firstName: firstName, middleName: middleName, lgu: lgu, barangay: barangay, flaggedOnly: flaggedOnly);
    }
    try {
      final w = _voterWhere(lastName: lastName, firstName: firstName, middleName: middleName, lgu: lgu, barangay: barangay);
      if (flaggedOnly == true) w.where.add('f.voter_id IS NOT NULL');
      final rows = await _rows('$_localVoterSelect ${_whereSql(w.where)} ORDER BY v.lastname, v.firstname LIMIT 100', w.params);
      return rows.map(Voter.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Voter>> _getVotersOnline({
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    bool? flaggedOnly,
  }) async {
    bool has(String? v) => v != null && v.trim().isNotEmpty && v != 'All';

    try {
      var req = client.from('voters').select();
      if (has(lastName)) req = req.ilike('lastname', '%${lastName!.trim()}%');
      if (has(firstName)) req = req.ilike('firstname', '%${firstName!.trim()}%');
      if (has(middleName)) req = req.ilike('middlename', '%${middleName!.trim()}%');
      if (has(barangay)) req = req.ilike('brgy', barangay!.trim());
      if (flaggedOnly == true) {
        req = req.eq('is_flagged', true);
      }
      final response = await req
          .order('lastname', ascending: true)
          .order('firstname', ascending: true)
          .limit(100);
      var results = (response as List).map((row) => Voter.fromJson(row as Map<String, dynamic>)).toList();

      // LGU is filtered locally because not every voters import carries an `lgu` column
      if (has(lgu)) {
        results = results.where((v) => v.lgu.isEmpty || v.lgu.toUpperCase() == lgu!.toUpperCase()).toList();
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  /// Flags a voter. Stored in `voter_flags`, which syncs to Supabase (a trigger there also sets
  /// `voters.is_flagged`), so this works offline.
  Future<void> flagVoter(String id, String reason) async {
    await db.writeTransaction((tx) async {
      await _insert(tx, 'voter_flags', {
        'id': uuid.v4(),
        'voter_id': id,
        'reason': reason,
        'flagged_by': currentAuthUser?.email,
        'created_at': _now(),
      });
      await _log(tx, action: 'FLAG_VOTER', entityType: 'Voter', entityId: id, details: {'reason': reason});
    });
  }

  // ==========================================
  // Activity Logs Query
  // ==========================================
  /// Online only: activity logs are uploaded from every device but never downloaded.
  Future<List<ActivityLog>> getActivityLogs({int limit = 100}) async {
    try {
      final response = await client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((row) => ActivityLog.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // Users & RBAC Permissions
  // ==========================================
  Future<List<AppUser>> getUsers() async {
    try {
      final rows = await _rows('SELECT * FROM users ORDER BY created_date DESC');
      return rows.map(AppUser.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  Future<AppUser?> getCurrentAppUser() async {
    try {
      final authUser = currentAuthUser;
      if (authUser == null) return null;
      final email = authUser.email;

      // Local first, so an offline cold start still knows the user's role and permissions.
      // Profile rows created outside Supabase Auth may not share the auth id; match by email instead.
      var row = await _getRow('users', authUser.id);
      if (row == null && email != null && email.isNotEmpty) {
        final rows = await _rows('SELECT * FROM users WHERE email LIKE ? LIMIT 1', [email]);
        if (rows.isNotEmpty) row = rows.first;
      }
      if (row != null) return AppUser.fromJson(row);

      // First login on this device: users hasn't synced yet, so ask Supabase.
      var res = await client.from('users').select().eq('id', authUser.id).maybeSingle();
      if (res == null && email != null && email.isNotEmpty) {
        res = await client.from('users').select().ilike('email', email).limit(1).maybeSingle();
      }

      if (res == null) {
        debugPrint('No users row found for auth user ${authUser.id} ($email)');
        return null;
      }
      return AppUser.fromJson(res);
    } catch (e) {
      debugPrint('Failed to load users row: $e');
      return null;
    }
  }

  Future<AppUser> updateAppUser(AppUser user) async {
    final payload = user.toJson();
    payload['updated_date'] = _now();
    await db.writeTransaction((tx) async {
      await _update(tx, 'users', user.id, payload);
      await _log(
        tx,
        action: 'UPDATE_USER',
        entityType: 'User',
        entityId: user.id,
        details: {'role': user.role, 'permissions': user.permissions},
      );
    });
    return AppUser.fromJson((await _getRow('users', user.id))!);
  }

  /// Records the sign-in time shown in Settings > Users. Best effort.
  Future<void> touchLastLogin(String userId) async {
    try {
      await db.execute('UPDATE users SET last_login = ? WHERE id = ?', [_now(), userId]);
    } catch (_) {}
  }

  /// Creates a Supabase Auth account plus its `users` profile (same id) through the
  /// `admin-users` Edge Function, which holds the service-role key. Online only.
  Future<AppUser> createUserAccount({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String role,
    required List<String> permissions,
  }) async {
    final data = await _adminUsers({
      'action': 'create',
      'email': email,
      'password': password,
      'firstname': firstname,
      'lastname': lastname,
      'role': role,
      'permissions': permissions,
    });
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    await logActivity(
      action: 'CREATE_USER',
      entityType: 'User',
      entityId: user.id,
      details: {'email': email, 'role': role, 'permissions': permissions},
    );
    return user;
  }

  /// Sets a new password for another user's Auth account. Online only.
  Future<void> setUserPassword(String userId, String password) async {
    await _adminUsers({'action': 'set_password', 'user_id': userId, 'password': password});
    await logActivity(action: 'RESET_PASSWORD', entityType: 'User', entityId: userId);
  }

  /// Activates or deactivates (bans) a user's Auth account and profile. Online only.
  Future<void> setUserStatus(String userId, String status) async {
    await _adminUsers({'action': 'set_status', 'user_id': userId, 'status': status});
    // Mirror locally so the list updates before the change syncs back down.
    await db.execute('UPDATE users SET status = ?, updated_date = ? WHERE id = ?', [status, _now(), userId]);
    await logActivity(
      action: status == 'active' ? 'ACTIVATE_USER' : 'DEACTIVATE_USER',
      entityType: 'User',
      entityId: userId,
    );
  }

  Future<Map<String, dynamic>> _adminUsers(Map<String, dynamic> body) async {
    try {
      final res = await client.functions.invoke('admin-users', body: body);
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error']?.toString() : null;
      throw Exception(message ?? 'User management request failed (${e.status}).');
    } catch (e) {
      debugPrint('admin-users call failed: $e');
      throw Exception('Could not reach the server. Managing user accounts requires an internet connection.');
    }
  }

  // ==========================================
  // Locations (barangays) & Puroks
  // ==========================================
  static const _norm = "UPPER(TRIM(COALESCE(%s, '')))";
  static String _n(String col) => _norm.replaceAll('%s', col);

  /// Every `locations` row with household, member and purok counts. Households and members
  /// reference a barangay by its LGU + barangay text, matched case- and space-insensitively.
  Future<List<Location>> getLocationsAdmin() async {
    final rows = await _rows('''
      SELECT l.id, l.lgu, l.barangay, l.latitude, l.longitude,
        COALESCE(h.n, 0) AS household_count,
        COALESCE(m.n, 0) AS member_count,
        (SELECT COUNT(*) FROM puroks p WHERE p.location_id = l.id) AS purok_count
      FROM locations l
      LEFT JOIN (SELECT ${_n('lgu')} AS lgu, ${_n('barangay')} AS brgy, COUNT(*) AS n FROM households GROUP BY 1, 2) h
        ON h.lgu = ${_n('l.lgu')} AND h.brgy = ${_n('l.barangay')}
      LEFT JOIN (SELECT ${_n('lgu')} AS lgu, ${_n('barangay')} AS brgy, COUNT(*) AS n FROM family_members GROUP BY 1, 2) m
        ON m.lgu = ${_n('l.lgu')} AND m.brgy = ${_n('l.barangay')}
      ORDER BY ${_n('l.lgu')}, ${_n('l.barangay')}
    ''');
    return rows.map(Location.fromJson).toList();
  }

  Future<void> _checkUniqueLocation(String lgu, String barangay, {String? exceptId}) async {
    final dup = await db.getOptional(
      "SELECT id FROM locations WHERE ${_n('lgu')} = ? AND ${_n('barangay')} = ? AND id != ?",
      [lgu.trim().toUpperCase(), barangay.trim().toUpperCase(), exceptId ?? ''],
    );
    if (dup != null) throw Exception('$barangay, $lgu already exists.');
  }

  Future<Location> createLocation({
    required String lgu,
    required String barangay,
    double? latitude,
    double? longitude,
  }) async {
    await _checkUniqueLocation(lgu, barangay);
    final id = uuid.v4();
    await db.writeTransaction((tx) async {
      await _insert(tx, 'locations', {
        'id': id,
        'lgu': lgu.trim().toUpperCase(),
        'barangay': barangay.trim().toUpperCase(),
        'latitude': latitude,
        'longitude': longitude,
      });
      await _log(tx, action: 'CREATE', entityType: 'Location', entityId: id, details: {'lgu': lgu, 'barangay': barangay});
    });
    return Location.fromJson((await _getRow('locations', id))!);
  }

  /// Renaming is blocked while households or members use the barangay, since they store its name as text.
  Future<void> updateLocation(Location before, {
    required String lgu,
    required String barangay,
    double? latitude,
    double? longitude,
  }) async {
    final newLgu = lgu.trim().toUpperCase();
    final newBrgy = barangay.trim().toUpperCase();
    final renamed = newLgu != before.lgu.trim().toUpperCase() || newBrgy != before.barangay.trim().toUpperCase();
    if (renamed) {
      if (before.inUse) {
        throw Exception('Cannot rename ${before.barangay}: ${before.householdCount} households and '
            '${before.memberCount} members are registered under it.');
      }
      await _checkUniqueLocation(newLgu, newBrgy, exceptId: before.id);
    }
    await db.writeTransaction((tx) async {
      await _update(tx, 'locations', before.id, {
        'lgu': newLgu,
        'barangay': newBrgy,
        'latitude': latitude,
        'longitude': longitude,
      });
      await _log(tx, action: 'UPDATE', entityType: 'Location', entityId: before.id,
          details: {'lgu': newLgu, 'barangay': newBrgy, 'latitude': latitude, 'longitude': longitude});
    });
  }

  /// Deleting cascades to the barangay's puroks and officers in Supabase, so it is only
  /// allowed once no household or member is registered under it.
  Future<void> deleteLocation(Location location) async {
    if (location.inUse) {
      throw Exception('Cannot delete ${location.barangay}: ${location.householdCount} households and '
          '${location.memberCount} members are registered under it.');
    }
    await db.writeTransaction((tx) async {
      // Mirror the Supabase ON DELETE CASCADE locally; the server applies it on upload.
      await tx.execute('DELETE FROM officers WHERE location_id = ?', [location.id]);
      await tx.execute('DELETE FROM puroks WHERE location_id = ?', [location.id]);
      await tx.execute('DELETE FROM locations WHERE id = ?', [location.id]);
      await _log(tx, action: 'DELETE', entityType: 'Location', entityId: location.id,
          details: {'lgu': location.lgu, 'barangay': location.barangay});
    });
  }

  /// Households and members assigned to a purok.
  Future<({int households, int members})> purokUsage(String purokId) async {
    final row = await db.get(
      'SELECT (SELECT COUNT(*) FROM households WHERE purok_id = ?) AS h, '
      '(SELECT COUNT(*) FROM family_members WHERE purok_id = ?) AS m',
      [purokId, purokId],
    );
    return (households: row['h'] as int, members: row['m'] as int);
  }

  Future<void> _checkUniquePurok(String locationId, String name, {String? exceptId}) async {
    final dup = await db.getOptional(
      "SELECT id FROM puroks WHERE location_id = ? AND ${_n('name')} = ? AND id != ?",
      [locationId, name.trim().toUpperCase(), exceptId ?? ''],
    );
    if (dup != null) throw Exception('Purok "${name.trim()}" already exists in this barangay.');
  }

  Future<void> createPurok(String locationId, String name) async {
    if (name.trim().isEmpty) throw Exception('Purok name is required.');
    await _checkUniquePurok(locationId, name);
    final id = uuid.v4();
    await db.writeTransaction((tx) async {
      await _insert(tx, 'puroks', {'id': id, 'location_id': locationId, 'name': name.trim()});
      await _log(tx, action: 'CREATE', entityType: 'Purok', entityId: id, details: {'name': name.trim(), 'location_id': locationId});
    });
  }

  /// Renaming is blocked while households or members use the purok, since they store its name as text.
  Future<void> renamePurok(String locationId, String purokId, String name) async {
    if (name.trim().isEmpty) throw Exception('Purok name is required.');
    final usage = await purokUsage(purokId);
    if (usage.households > 0 || usage.members > 0) {
      throw Exception('Cannot rename: ${usage.households} households and ${usage.members} members are assigned to this purok.');
    }
    await _checkUniquePurok(locationId, name, exceptId: purokId);
    await db.writeTransaction((tx) async {
      await _update(tx, 'puroks', purokId, {'name': name.trim()});
      await _log(tx, action: 'UPDATE', entityType: 'Purok', entityId: purokId, details: {'name': name.trim()});
    });
  }

  Future<void> deletePurok(String purokId, String name) async {
    final usage = await purokUsage(purokId);
    if (usage.households > 0 || usage.members > 0) {
      throw Exception('Cannot delete: ${usage.households} households and ${usage.members} members are assigned to this purok.');
    }
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM officers WHERE purok_id = ?', [purokId]);
      await tx.execute('DELETE FROM puroks WHERE id = ?', [purokId]);
      await _log(tx, action: 'DELETE', entityType: 'Purok', entityId: purokId, details: {'name': name});
    });
  }

  // ==========================================
  // Organization Structure (Officers)
  // ==========================================
  /// Officers of one barangay: its federation officers and those of every purok in it.
  Future<List<Officer>> getOfficers(String locationId) async {
    final rows = await _rows('''
      SELECT o.*,
        TRIM(COALESCE(m.lastname, '') || ', ' || COALESCE(m.firstname, '') || ' ' || COALESCE(m.middlename, '')) AS member_name,
        m.contact_number,
        p.name AS purok_name
      FROM officers o
      LEFT JOIN family_members m ON m.id = o.member_id
      LEFT JOIN puroks p ON p.id = o.purok_id
      WHERE o.location_id = ?
      ORDER BY o.created_at
    ''', [locationId]);
    return rows.map(Officer.fromJson).toList();
  }

  /// Members registered in [location] (and in [purokId], when given) whose name matches [query].
  Future<List<FamilyMember>> searchMembersForOfficer(Location location, {String? purokId, String query = ''}) async {
    final params = <Object?>[location.lgu.trim().toUpperCase(), location.barangay.trim().toUpperCase()];
    var where = "${_n('lgu')} = ? AND ${_n('barangay')} = ?";
    if (purokId != null) {
      where += ' AND purok_id = ?';
      params.add(purokId);
    }
    if (query.trim().isNotEmpty) {
      final q = '%${_escapeLike(query)}%';
      where += r" AND (firstname LIKE ? ESCAPE '\' OR lastname LIKE ? ESCAPE '\')";
      params.addAll([q, q]);
    }
    final rows = await _rows('SELECT * FROM family_members WHERE $where ORDER BY lastname, firstname LIMIT 30', params);
    return rows.map(FamilyMember.fromJson).toList();
  }

  /// Inserts or updates an officer, enforcing the Supabase constraints locally first: a change
  /// that violates them would be discarded on upload and the edit silently lost.
  Future<void> saveOfficer(Officer officer, {required bool isNew}) async {
    if (!OfficerPositions.all.contains(officer.position)) {
      throw Exception('Unknown position "${officer.position}".');
    }
    if (officer.memberId.isEmpty) throw Exception('Select the member who holds this position.');
    final isPurok = officer.level == Officer.levelPurok;
    if (isPurok && officer.purokId == null) throw Exception('Purok officers need a purok.');
    if (!isPurok && officer.purokId != null) throw Exception('Barangay officers cannot have a purok.');

    if (OfficerPositions.unique.contains(officer.position)) {
      final taken = await db.getOptional(
        isPurok
            ? "SELECT id FROM officers WHERE level = 'purok' AND purok_id = ? AND position = ? AND id != ?"
            : "SELECT id FROM officers WHERE level = 'barangay' AND location_id = ? AND position = ? AND id != ?",
        [isPurok ? officer.purokId : officer.locationId, officer.position, officer.id],
      );
      if (taken != null) {
        throw Exception('The ${officer.position} position is already filled. Remove the current holder first.');
      }
    }

    final now = _now();
    await db.writeTransaction((tx) async {
      final row = {...officer.toJson(), 'updated_at': now};
      if (isNew) {
        await _insert(tx, 'officers', {...row, 'created_at': now});
      } else {
        row.remove('created_at');
        await _update(tx, 'officers', officer.id, row);
      }
      await _log(
        tx,
        action: isNew ? 'ASSIGN_OFFICER' : 'UPDATE_OFFICER',
        entityType: 'Officer',
        entityId: officer.id,
        details: {
          'position': officer.position,
          'level': officer.level,
          'location_id': officer.locationId,
          'purok_id': officer.purokId,
          'member_id': officer.memberId,
        },
      );
    });
  }

  Future<void> deleteOfficer(Officer officer) async {
    await db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM officers WHERE id = ?', [officer.id]);
      await _log(tx, action: 'REMOVE_OFFICER', entityType: 'Officer', entityId: officer.id,
          details: {'position': officer.position, 'level': officer.level, 'member': officer.memberName});
    });
  }

  // ==========================================
  // Dashboard Aggregates
  // ==========================================
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final row = await db.get('''
      SELECT
        (SELECT COUNT(*) FROM households) AS total_households,
        (SELECT COUNT(*) FROM family_members) AS registered_members,
        (SELECT COUNT(*) FROM family_members WHERE is_cooperative_member = 1) AS coop_members,
        (SELECT COUNT(*) FROM family_members WHERE is_voter = 1) AS total_voters,
        (SELECT COALESCE(SUM(amount), 0) FROM dues_payments) AS total_collections
    ''');
    return {
      'totalHouseholds': row['total_households'] as int,
      'registeredMembers': row['registered_members'] as int,
      'coopMembers': row['coop_members'] as int,
      'totalVoters': row['total_voters'] as int,
      'totalCollections': (row['total_collections'] as num).toDouble(),
    };
  }

  /// Household, member and voter counts per barangay, including `locations` rows with no data yet.
  /// Groups on the raw columns so the `lgu_brgy` indexes are used, then merges spelling variants
  /// in Dart with the same case- and space-insensitive match as [getLocationsAdmin].
  Future<List<BarangayStat>> getBarangayReportStats() async {
    final results = await Future.wait([
      _rows('SELECT lgu, barangay FROM locations'),
      _rows('SELECT lgu, barangay, COUNT(*) AS n FROM households GROUP BY lgu, barangay'),
      _rows('SELECT lgu, barangay, COUNT(*) AS n, SUM(is_voter = 1) AS v FROM family_members GROUP BY lgu, barangay'),
    ]);

    final stats = <String, BarangayStat>{};
    void add(Map<String, dynamic> r, {int households = 0, int members = 0, int voters = 0}) {
      final lgu = (r['lgu'] as String? ?? '').trim().toUpperCase();
      var barangay = (r['barangay'] as String? ?? '').trim().toUpperCase();
      if (barangay.isEmpty) barangay = '(UNASSIGNED)';
      final key = '$lgu|$barangay';
      final row = BarangayStat(lgu: lgu, barangay: barangay, households: households, members: members, voters: voters);
      stats[key] = stats[key] == null ? row : stats[key]! + row;
    }

    for (final r in results[0]) {
      add(r);
    }
    for (final r in results[1]) {
      add(r, households: r['n'] as int);
    }
    for (final r in results[2]) {
      add(r, members: r['n'] as int, voters: (r['v'] as num? ?? 0).toInt());
    }
    return stats.values.toList()
      ..sort((a, b) {
        final c = a.lgu.compareTo(b.lgu);
        return c != 0 ? c : a.barangay.compareTo(b.barangay);
      });
  }
}
