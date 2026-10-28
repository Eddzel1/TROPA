import 'dart:convert';

import '../core/geo.dart';
import '../core/ph_time.dart';

/// Reads a boolean from either a Supabase row (true/false) or a local SQLite row (1/0).
bool asBool(dynamic v) => v == true || v == 1;

/// Reads a string list from either a JSON array or JSON-encoded text (how SQLite stores it).
List<String>? asStringList(dynamic v) {
  if (v is String) {
    try {
      v = jsonDecode(v);
    } catch (_) {
      return null;
    }
  }
  return v is List ? v.map((e) => e.toString()).toList() : null;
}

// ==========================================
// 1. Household
// ==========================================
class Household {
  final String id;
  final String householdName;
  final String lgu;
  final String barangay;
  final String purok;
  final String? purokId;
  final String? householdLeaderId;
  final int totalMembers;
  final int activeMembers;
  final String status;
  final String? housePictureUrl;
  final String? housePicturePath;
  final double? latitude;
  final double? longitude;
  final bool isArchived;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String createdBy;

  Household({
    required this.id,
    required this.householdName,
    required this.lgu,
    required this.barangay,
    required this.purok,
    this.purokId,
    this.householdLeaderId,
    required this.totalMembers,
    required this.activeMembers,
    required this.status,
    this.housePictureUrl,
    this.housePicturePath,
    this.latitude,
    this.longitude,
    this.isArchived = false,
    required this.createdDate,
    required this.updatedDate,
    required this.createdBy,
  });

  factory Household.fromJson(Map<String, dynamic> json) => Household(
        id: json['id']?.toString() ?? '',
        householdName: json['household_name']?.toString() ?? 'Unnamed Household',
        lgu: json['lgu']?.toString() ?? 'VALENCIA CITY',
        barangay: json['barangay']?.toString() ?? '',
        purok: json['purok']?.toString() ?? '',
        purokId: json['purok_id']?.toString(),
        householdLeaderId: json['household_leader_id']?.toString(),
        totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
        activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'active',
        housePictureUrl: json['house_picture_url']?.toString(),
        housePicturePath: json['house_picture_path']?.toString(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isArchived: asBool(json['is_archived']),
        createdDate: json['created_date'] != null ? parsePh(json['created_date'].toString()) ?? phNow() : phNow(),
        updatedDate: json['updated_date'] != null ? parsePh(json['updated_date'].toString()) ?? phNow() : phNow(),
        createdBy: json['created_by']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'household_name': householdName,
        'lgu': lgu,
        'barangay': barangay,
        'purok': purok,
        // Always sent so a purok that isn't in the puroks table clears a stale link
        'purok_id': purokId,
        if (householdLeaderId != null) 'household_leader_id': householdLeaderId,
        'total_members': totalMembers,
        'active_members': activeMembers,
        'status': status,
        if (housePictureUrl != null) 'house_picture_url': housePictureUrl,
        if (housePicturePath != null) 'house_picture_path': housePicturePath,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'created_date': toPhIso(createdDate),
        'updated_date': toPhIso(updatedDate),
        'created_by': createdBy,
      };

  Household copyWith({
    String? id,
    String? householdName,
    String? lgu,
    String? barangay,
    String? purok,
    String? purokId,
    String? householdLeaderId,
    int? totalMembers,
    int? activeMembers,
    String? status,
    String? housePictureUrl,
    String? housePicturePath,
    double? latitude,
    double? longitude,
    DateTime? createdDate,
    DateTime? updatedDate,
    String? createdBy,
  }) {
    return Household(
      id: id ?? this.id,
      householdName: householdName ?? this.householdName,
      lgu: lgu ?? this.lgu,
      barangay: barangay ?? this.barangay,
      purok: purok ?? this.purok,
      purokId: purokId ?? this.purokId,
      householdLeaderId: householdLeaderId ?? this.householdLeaderId,
      totalMembers: totalMembers ?? this.totalMembers,
      activeMembers: activeMembers ?? this.activeMembers,
      status: status ?? this.status,
      housePictureUrl: housePictureUrl ?? this.housePictureUrl,
      housePicturePath: housePicturePath ?? this.housePicturePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// ==========================================
// 2. FamilyMember
// ==========================================
class FamilyMember {
  final String id;
  final String householdId;
  final String firstname;
  final String lastname;
  final String? middlename;
  final String? extension;
  final String lgu;
  final String barangay;
  final String purok;
  final String? purokId;
  final String sector;
  final bool isVoter;
  final String? voterBarangay;
  final int? voterId;
  final String? contactNumber;
  final bool isHouseholdLeader;
  final bool isCooperativeMember;
  final DateTime? membershipDate;
  final DateTime? birthDate;
  final int? age;
  final double? latitude;
  final double? longitude;
  final String? religion;
  final String? school;
  final String? yearLevel;
  final String? gender; // 'Male' / 'Female'
  final String? listingStatus;
  final String? profilePictureUrl;
  final String? profilePicturePath;
  final bool? phicMember;
  final String? phicNo;
  final bool? trucareMember;

  /// TROPA ID card number ('TRP-2600001'). Assigned by the server, so null until a new member syncs;
  /// left out of [toJson] so devices never send it.
  final String? idNumber;
  final bool isArchived;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String? createdBy;

  FamilyMember({
    required this.id,
    required this.householdId,
    required this.firstname,
    required this.lastname,
    this.middlename,
    this.extension,
    required this.lgu,
    required this.barangay,
    required this.purok,
    this.purokId,
    required this.sector,
    required this.isVoter,
    this.voterBarangay,
    this.voterId,
    this.contactNumber,
    required this.isHouseholdLeader,
    required this.isCooperativeMember,
    this.membershipDate,
    this.birthDate,
    this.age,
    this.latitude,
    this.longitude,
    this.religion,
    this.school,
    this.yearLevel,
    this.gender,
    this.listingStatus,
    this.profilePictureUrl,
    this.profilePicturePath,
    this.phicMember,
    this.phicNo,
    this.trucareMember,
    this.idNumber,
    this.isArchived = false,
    required this.createdDate,
    required this.updatedDate,
    this.createdBy,
  });

  String get fullName =>
      '$lastname, $firstname${middlename != null && middlename!.isNotEmpty ? ' $middlename' : ''}${extension != null && extension!.isNotEmpty ? ' $extension' : ''}';

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        id: json['id']?.toString() ?? '',
        householdId: json['household_id']?.toString() ?? '',
        firstname: json['firstname']?.toString() ?? '',
        lastname: json['lastname']?.toString() ?? '',
        middlename: json['middlename']?.toString(),
        extension: json['extension']?.toString(),
        lgu: json['lgu']?.toString() ?? 'VALENCIA CITY',
        barangay: json['barangay']?.toString() ?? '',
        purok: json['purok']?.toString() ?? '',
        purokId: json['purok_id']?.toString(),
        sector: json['sector']?.toString() ?? 'General',
        isVoter: asBool(json['is_voter']),
        voterBarangay: json['voter_barangay']?.toString(),
        voterId: (json['voter_id'] as num?)?.toInt(),
        contactNumber: json['contact_number']?.toString(),
        isHouseholdLeader: asBool(json['is_household_leader']),
        isCooperativeMember: asBool(json['is_cooperative_member']),
        membershipDate: json['membership_date'] != null ? DateTime.tryParse(json['membership_date'].toString()) : null,
        birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date'].toString()) : null,
        age: (json['age'] as num?)?.toInt(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        religion: json['religion']?.toString(),
        school: json['school']?.toString(),
        yearLevel: json['year_level']?.toString(),
        gender: json['gender']?.toString(),
        listingStatus: json['listing_status']?.toString() ?? 'MEMBER',
        profilePictureUrl: json['profile_picture_url']?.toString(),
        profilePicturePath: json['profile_picture_path']?.toString(),
        phicMember: asBool(json['phic_member']),
        phicNo: json['phic_no']?.toString(),
        trucareMember: asBool(json['trucare_member']),
        idNumber: json['id_number']?.toString(),
        isArchived: asBool(json['is_archived']),
        createdDate: json['created_date'] != null ? parsePh(json['created_date'].toString()) ?? phNow() : phNow(),
        updatedDate: json['updated_date'] != null ? parsePh(json['updated_date'].toString()) ?? phNow() : phNow(),
        createdBy: json['created_by']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'household_id': householdId,
        'firstname': firstname,
        'lastname': lastname,
        if (middlename != null) 'middlename': middlename,
        if (extension != null) 'extension': extension,
        'lgu': lgu,
        'barangay': barangay,
        'purok': purok,
        if (purokId != null) 'purok_id': purokId,
        'sector': sector,
        'is_voter': isVoter,
        if (voterBarangay != null) 'voter_barangay': voterBarangay,
        if (voterId != null) 'voter_id': voterId,
        if (contactNumber != null) 'contact_number': contactNumber,
        'is_household_leader': isHouseholdLeader,
        'is_cooperative_member': isCooperativeMember,
        if (membershipDate != null) 'membership_date': membershipDate!.toIso8601String().split('T').first,
        if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T').first,
        if (age != null) 'age': age,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (religion != null) 'religion': religion,
        if (school != null) 'school': school,
        if (yearLevel != null) 'year_level': yearLevel,
        if (gender != null) 'gender': gender,
        if (listingStatus != null) 'listing_status': listingStatus,
        if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
        if (profilePicturePath != null) 'profile_picture_path': profilePicturePath,
        'phic_member': phicMember ?? false,
        if (phicNo != null) 'phic_no': phicNo,
        'trucare_member': trucareMember ?? false,
        'created_date': toPhIso(createdDate),
        'updated_date': toPhIso(updatedDate),
        if (createdBy != null) 'created_by': createdBy,
      };
}

// ==========================================
// 3. DuesPayment
// ==========================================
class DuesPayment {
  final String id;
  final String memberId;
  final String householdId;
  final double amount;
  final String paymentMonth;
  final int? monthsCovered;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String status;
  final String collectedBy;
  final String createdBy;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String? receiptId;
  final String? voidReason;

  DuesPayment({
    required this.id,
    required this.memberId,
    required this.householdId,
    required this.amount,
    required this.paymentMonth,
    this.monthsCovered,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.status,
    required this.collectedBy,
    required this.createdBy,
    required this.createdDate,
    required this.updatedDate,
    this.receiptId,
    this.voidReason,
  });

  static const statusCompleted = 'completed';
  static const statusVoid = 'void';

  bool get isVoid => status == statusVoid;

  factory DuesPayment.fromJson(Map<String, dynamic> json) => DuesPayment(
        id: json['id']?.toString() ?? '',
        memberId: json['member_id']?.toString() ?? '',
        householdId: json['household_id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        paymentMonth: json['payment_month']?.toString() ?? '',
        monthsCovered: (json['months_covered'] as num?)?.toInt() ?? 1,
        paymentDate: json['payment_date'] != null ? parsePh(json['payment_date'].toString()) ?? phNow() : phNow(),
        paymentMethod: json['payment_method']?.toString() ?? 'Cash',
        referenceNumber: json['reference_number']?.toString(),
        notes: json['notes']?.toString(),
        status: json['status']?.toString() ?? 'completed',
        collectedBy: json['collected_by']?.toString() ?? 'Admin',
        createdBy: json['created_by']?.toString() ?? '',
        createdDate: json['created_date'] != null ? parsePh(json['created_date'].toString()) ?? phNow() : phNow(),
        updatedDate: json['updated_date'] != null ? parsePh(json['updated_date'].toString()) ?? phNow() : phNow(),
        receiptId: json['receipt_id']?.toString(),
        voidReason: json['void_reason']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'household_id': householdId,
        'amount': amount,
        'payment_month': paymentMonth,
        'months_covered': monthsCovered ?? 1,
        'payment_date': toPhIso(paymentDate),
        'payment_method': paymentMethod,
        if (referenceNumber != null) 'reference_number': referenceNumber,
        if (notes != null) 'notes': notes,
        'status': status,
        'collected_by': collectedBy,
        'created_by': createdBy,
        'created_date': toPhIso(createdDate),
        'updated_date': toPhIso(updatedDate),
        if (receiptId != null) 'receipt_id': receiptId,
        if (voidReason != null) 'void_reason': voidReason,
      };
}

/// A `dues_rates` row: the monthly dues per member from [effectiveMonth] (`YYYY-MM`) onward.
class DuesRate {
  final String id;
  final double amount;
  final String effectiveMonth;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DuesRate({
    required this.id,
    required this.amount,
    required this.effectiveMonth,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DuesRate.fromJson(Map<String, dynamic> json) => DuesRate(
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        effectiveMonth: json['effective_month']?.toString() ?? '',
        createdBy: json['created_by']?.toString(),
        createdAt: parsePh(json['created_at']?.toString()) ?? phNow(),
        updatedAt: parsePh(json['updated_at']?.toString()) ?? phNow(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'effective_month': effectiveMonth,
        'created_by': createdBy,
        'created_at': toPhIso(createdAt),
        'updated_at': toPhIso(updatedAt),
      };
}

/// A member as the Dues page sees them: who they are, where, since when, and how many months
/// their non-void payments cover. Balances are worked out in lib/core/dues_math.dart.
class DuesMember {
  final String id;
  final String firstname;
  final String lastname;
  final String? middlename;
  final String? extension;
  final String householdId;
  final String? householdName;
  final String lgu;
  final String barangay;
  final String purok;
  final DateTime? membershipDate;
  final bool isCoopMember;
  final int monthsPaid;

  DuesMember({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.middlename,
    this.extension,
    required this.householdId,
    this.householdName,
    required this.lgu,
    required this.barangay,
    required this.purok,
    this.membershipDate,
    required this.isCoopMember,
    required this.monthsPaid,
  });

  String get fullName =>
      '$lastname, $firstname${middlename != null && middlename!.isNotEmpty ? ' $middlename' : ''}${extension != null && extension!.isNotEmpty ? ' $extension' : ''}';

  factory DuesMember.fromRow(Map<String, dynamic> r) => DuesMember(
        id: r['id']?.toString() ?? '',
        firstname: r['firstname']?.toString() ?? '',
        lastname: r['lastname']?.toString() ?? '',
        middlename: r['middlename']?.toString(),
        extension: r['extension']?.toString(),
        householdId: r['household_id']?.toString() ?? '',
        householdName: r['household_name']?.toString(),
        lgu: r['lgu']?.toString() ?? '',
        barangay: r['barangay']?.toString() ?? '',
        purok: r['purok']?.toString() ?? '',
        membershipDate: r['membership_date'] != null ? DateTime.tryParse(r['membership_date'].toString()) : null,
        isCoopMember: asBool(r['is_cooperative_member']),
        monthsPaid: (r['months_paid'] as num?)?.toInt() ?? 0,
      );
}

/// A household with its members, for the Dues page.
class DuesHousehold {
  final String id;
  final String householdName;
  final String lgu;
  final String barangay;
  final String purok;

  /// Members in the collector's barangays; only these can be billed here.
  final List<DuesMember> members;

  /// Members registered under a barangay outside the collector's, collected there instead.
  final int membersElsewhere;

  DuesHousehold({
    required this.id,
    required this.householdName,
    required this.lgu,
    required this.barangay,
    required this.purok,
    required this.members,
    this.membersElsewhere = 0,
  });
}

/// The barangays a user may collect dues for: [everywhere], or only [barangays].
class DuesScope {
  final bool everywhere;
  final List<LocationOption> barangays;

  const DuesScope({this.everywhere = false, this.barangays = const []});

  bool get isEmpty => !everywhere && barangays.isEmpty;

  /// `LGU|BARANGAY` keys, upper-cased and trimmed like the SQL match.
  List<String> get keys => [for (final b in barangays) '${b.lgu}|${b.barangay}'];

  /// Whether a member or household at [lgu], [barangay] is in this scope.
  bool covers(String lgu, String barangay) =>
      everywhere || keys.contains('${lgu.trim().toUpperCase()}|${barangay.trim().toUpperCase()}');
}

/// One receipt in the ledger: a household payment's per-member rows grouped by `receipt_id`, or a
/// single row logged on its own (then [id] is that row's id).
class DuesReceipt {
  final String id;
  final DateTime paymentDate;
  final double total;
  final int memberCount;
  final int monthsCovered;
  final String? firstMonth;
  final String? lastMonth;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String status;
  final String? voidReason;
  final String collectedBy;
  final String? householdName;
  final String? barangay;
  final String memberNames;

  DuesReceipt({
    required this.id,
    required this.paymentDate,
    required this.total,
    required this.memberCount,
    required this.monthsCovered,
    this.firstMonth,
    this.lastMonth,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.status,
    this.voidReason,
    required this.collectedBy,
    this.householdName,
    this.barangay,
    required this.memberNames,
  });

  bool get isVoid => status == DuesPayment.statusVoid;

  factory DuesReceipt.fromRow(Map<String, dynamic> r) => DuesReceipt(
        id: r['rid']?.toString() ?? '',
        paymentDate: parsePh(r['payment_date']?.toString()) ?? phNow(),
        total: (r['total'] as num?)?.toDouble() ?? 0,
        memberCount: (r['member_count'] as num?)?.toInt() ?? 0,
        monthsCovered: (r['months'] as num?)?.toInt() ?? 0,
        firstMonth: r['first_month']?.toString(),
        lastMonth: r['last_month']?.toString(),
        paymentMethod: r['payment_method']?.toString() ?? 'Cash',
        referenceNumber: r['reference_number']?.toString(),
        notes: r['notes']?.toString(),
        status: r['status']?.toString() ?? DuesPayment.statusCompleted,
        voidReason: r['void_reason']?.toString(),
        collectedBy: r['collected_by']?.toString() ?? '',
        householdName: r['household_name']?.toString(),
        barangay: r['barangay']?.toString(),
        memberNames: r['member_names']?.toString() ?? '',
      );
}

// ==========================================
// 4. AppUser
// ==========================================
class AppUser {
  final String id;
  final String email;
  final String firstname;
  final String lastname;
  final String status;
  final List<String> permissions;

  /// `locations.id`s this user collects dues for (see [duesCollectsEverywhere]).
  final List<String> duesBarangays;

  /// Sync only the [duesBarangays]' households, members and dues to this user's devices
  /// (bucket `by_barangay` in powersync/sync-rules.yaml) instead of every barangay.
  final bool syncAssignedOnly;
  final DateTime? lastLogin;
  final DateTime createdDate;
  final DateTime updatedDate;

  AppUser({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.status,
    required this.permissions,
    this.duesBarangays = const [],
    this.syncAssignedOnly = false,
    this.lastLogin,
    required this.createdDate,
    required this.updatedDate,
  });

  String get fullName => '$firstname $lastname'.trim().isEmpty ? email : '$firstname $lastname';

  bool hasPermission(String perm) => permissions.contains(AppPermissions.systemAdmin) || permissions.contains(perm);

  /// Whether this device should install the offline voter list for this user: only screens behind
  /// [AppPermissions.voterListPermissions] read it. Without it, voter searches go to Supabase.
  bool get needsVoterList => AppPermissions.voterListPermissions.any(hasPermission);

  /// System Admins, and admins with Manage users and no barangays set, collect dues anywhere.
  /// Matches `can_collect_dues_for` in supabase/migrations/20261019000000_dues_ledger.sql.
  bool get duesCollectsEverywhere =>
      permissions.contains(AppPermissions.systemAdmin) ||
      (duesBarangays.isEmpty && permissions.contains(AppPermissions.manageUsers));

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        firstname: json['firstname']?.toString() ?? '',
        lastname: json['lastname']?.toString() ?? '',
        status: json['status']?.toString() ?? 'active',
        permissions: asStringList(json['permissions']) ?? const [],
        duesBarangays: asStringList(json['dues_barangays']) ?? const [],
    syncAssignedOnly: asBool(json['sync_assigned_only']),
        lastLogin: json['last_login'] != null ? parsePh(json['last_login'].toString()) : null,
        createdDate: json['created_date'] != null ? parsePh(json['created_date'].toString()) ?? phNow() : phNow(),
        updatedDate: json['updated_date'] != null ? parsePh(json['updated_date'].toString()) ?? phNow() : phNow(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'status': status,
        'permissions': permissions,
        'dues_barangays': duesBarangays,
    'sync_assigned_only': syncAssignedOnly,
        if (lastLogin != null) 'last_login': toPhIso(lastLogin!),
        'created_date': toPhIso(createdDate),
        'updated_date': toPhIso(updatedDate),
      };
}

/// Permission keys checked by the router guards and the sidebar (see lib/router/router.dart).
class AppPermissions {
  static const systemAdmin = 'system_admin';
  static const manageHouseholds = 'manage_households';
  static const manageMembers = 'manage_members';
  static const deleteRecords = 'delete_records';
  static const duesCollection = 'dues_collection';
  static const formTracking = 'form_tracking';
  static const manageUsers = 'manage_users';
  static const manageLocations = 'manage_locations';
  static const publishOfflineData = 'publish_offline_data';
  static const viewAuditLogs = 'view_audit_logs';

  /// Permissions whose screens search the offline voter list: Tropa Finder, the member form's
  /// voter lookup, and the Voter Registry settings tab.
  static const voterListPermissions = {'tropa_finder', 'manage_members', publishOfflineData};

  /// Permission keys and labels, grouped under the headings the user form shows.
  static const groups = <String, Map<String, String>>{
    'Records': {
      'view_households': 'View households',
      'manage_households': 'Manage households',
      'view_members': 'View members',
      'manage_members': 'Manage members',
      duesCollection: 'Dues collection',
      deleteRecords: 'Delete records',
    },
    'Tools': {
      'view_dashboard': 'View dashboard',
      'view_reports': 'Reports & exports',
      'tropa_finder': 'Tropa Finder',
      formTracking: 'Form tracking',
    },
    'Administration': {
      manageUsers: 'Manage users',
      manageLocations: 'Manage locations & officers',
      publishOfflineData: 'Publish offline data',
      viewAuditLogs: 'View audit logs',
    },
  };

  static final labels = <String, String>{for (final g in groups.values) ...g};

  /// Named permission sets the user form can start from. Only the permissions are saved.
  static const presets = <String, List<String>>{
    'System Admin': [systemAdmin],
    'Admin': [
      'view_dashboard',
      'view_households',
      'manage_households',
      'view_members',
      'manage_members',
      'dues_collection',
      'view_reports',
      'tropa_finder',
      formTracking,
      manageUsers,
      manageLocations,
      publishOfflineData,
      viewAuditLogs
    ],
    'Field Encoder': ['view_dashboard', 'view_households', 'manage_households', 'view_members', 'manage_members'],
    'Dues Collector': ['view_dashboard', 'view_households', 'view_members', 'dues_collection'],
    'Auditor': ['view_dashboard', 'view_households', 'view_members', 'view_reports', 'tropa_finder'],
  };

  /// The preset whose permissions match [perms] exactly, or null.
  static String? matchingPreset(Iterable<String> perms) {
    final set = perms.toSet();
    for (final e in presets.entries) {
      if (e.value.length == set.length && set.containsAll(e.value)) return e.key;
    }
    return null;
  }

  /// Short label for a permission list, shown in the users list and the sidebar.
  static String summary(List<String> perms) {
    if (perms.isEmpty) return 'No access';
    if (perms.contains(systemAdmin)) return 'System Admin';
    return matchingPreset(perms) ?? 'Custom access';
  }
}

// ==========================================
// 5. Location (barangay) / Purok / Officer
// ==========================================
/// A `locations` row (one barangay of an LGU) with live usage counts for the admin screen.
class Location {
  final String id;
  final String lgu;
  final String barangay;
  final double? latitude;
  final double? longitude;
  final int householdCount;
  final int memberCount;
  final int purokCount;

  /// Dues starting month (`YYYY-MM`) that new members of this barangay adopt, or null.
  final String? duesStartMonth;

  Location({
    required this.id,
    required this.lgu,
    required this.barangay,
    this.latitude,
    this.longitude,
    this.householdCount = 0,
    this.memberCount = 0,
    this.purokCount = 0,
    this.duesStartMonth,
  });

  bool get inUse => householdCount > 0 || memberCount > 0;

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['id']?.toString() ?? '',
        lgu: json['lgu']?.toString() ?? '',
        barangay: json['barangay']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        householdCount: (json['household_count'] as num?)?.toInt() ?? 0,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        purokCount: (json['purok_count'] as num?)?.toInt() ?? 0,
        duesStartMonth: (json['dues_start_month']?.toString() ?? '').isEmpty ? null : json['dues_start_month'].toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lgu': lgu,
        'barangay': barangay,
        'latitude': latitude,
        'longitude': longitude,
        'dues_start_month': duesStartMonth,
      };
}

/// Household, member and voter counts for one barangay (or a total across several), for Reports.
/// Voters are members flagged `is_voter`.
class BarangayStat {
  final String lgu;
  final String barangay;
  final int households;
  final int members;
  final int voters;

  const BarangayStat({
    required this.lgu,
    required this.barangay,
    this.households = 0,
    this.members = 0,
    this.voters = 0,
  });

  static double _ratio(int a, int b) => b == 0 ? 0 : a / b;

  double get votersPerMember => _ratio(voters, members);
  double get votersPerHousehold => _ratio(voters, households);
  double get membersPerHousehold => _ratio(members, households);

  BarangayStat operator +(BarangayStat o) => BarangayStat(
        lgu: lgu,
        barangay: barangay,
        households: households + o.households,
        members: members + o.members,
        voters: voters + o.voters,
      );
}

/// Officer positions allowed by the `officers_position_check` constraint.
class OfficerPositions {
  static const president = 'President';
  static const vicePresident = 'Vice President';
  static const secretary = 'Secretary';
  static const treasurer = 'Treasurer';
  static const auditor = 'Auditor';
  static const boardMember = 'Board Member';

  static const all = [president, vicePresident, secretary, treasurer, auditor, boardMember];

  /// Positions with at most one holder per barangay (or per purok); Board Member has many.
  static const unique = [president, vicePresident, secretary, treasurer, auditor];
}

/// An `officers` row. Level 'barangay' is the federation (no purok); level 'purok' needs a purok.
class Officer {
  static const levelBarangay = 'barangay';
  static const levelPurok = 'purok';

  final String id;
  final String level;
  final String locationId;
  final String? purokId;
  final String position;
  final String memberId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Display-only fields joined in by the query.
  final String memberName;
  final String? contactNumber;
  final String? purokName;

  Officer({
    required this.id,
    required this.level,
    required this.locationId,
    this.purokId,
    required this.position,
    required this.memberId,
    required this.createdAt,
    required this.updatedAt,
    this.memberName = '',
    this.contactNumber,
    this.purokName,
  });

  factory Officer.fromJson(Map<String, dynamic> json) => Officer(
        id: json['id']?.toString() ?? '',
        level: json['level']?.toString() ?? levelBarangay,
        locationId: json['location_id']?.toString() ?? '',
        purokId: json['purok_id']?.toString(),
        position: json['position']?.toString() ?? '',
        memberId: json['member_id']?.toString() ?? '',
        createdAt: parsePh(json['created_at']?.toString()) ?? phNow(),
        updatedAt: parsePh(json['updated_at']?.toString()) ?? phNow(),
        memberName: json['member_name']?.toString() ?? '',
        contactNumber: json['contact_number']?.toString(),
        purokName: json['purok_name']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level,
        'location_id': locationId,
        'purok_id': purokId,
        'position': position,
        'member_id': memberId,
        'created_at': toPhIso(createdAt),
        'updated_at': toPhIso(updatedAt),
      };
}

// ==========================================
// 6. Voter (Tropa Finder / Verification)
// ==========================================
class Voter {
  final String id;
  final int voterId;
  final String firstname;
  final String lastname;
  final String? middlename;
  final String? ext;
  final String lgu;
  final String barangay;
  final String? purok;
  final String? status;
  final String? pc;
  final String? hhl;
  final String precinctNo;
  final bool isFlagged;
  final String? flagReason;
  final bool isCoopMember;
  final String? matchedMemberId;

  Voter({
    required this.id,
    required this.voterId,
    required this.firstname,
    required this.lastname,
    this.middlename,
    this.ext,
    this.lgu = '',
    required this.barangay,
    this.purok,
    this.status,
    this.pc,
    this.hhl,
    required this.precinctNo,
    required this.isFlagged,
    this.flagReason,
    required this.isCoopMember,
    this.matchedMemberId,
  });

  String get fullName =>
      '$lastname, $firstname${middlename != null ? ' $middlename' : ''}${ext != null ? ' $ext' : ''}';

  factory Voter.fromJson(Map<String, dynamic> json) {
    // Column names vary between voters imports (e.g. `PC` vs `pc`, `ext.` vs `ext`), so match keys case-insensitively
    final lower = {for (final e in json.entries) e.key.toLowerCase(): e.value};
    String? str(List<String> keys) {
      for (final k in keys) {
        final v = lower[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    return Voter(
      id: json['id']?.toString() ?? '',
      voterId: (json['voter_id'] as num?)?.toInt() ?? 0,
      firstname: str(['firstname']) ?? '',
      lastname: str(['lastname']) ?? '',
      middlename: str(['middlename']),
      ext: str(['ext.', 'ext', 'extension', 'suffix']),
      lgu: str(['lgu']) ?? '',
      barangay: str(['brgy', 'barangay']) ?? '',
      purok: str(['purok']),
      status: str(['status', 'listing_status']),
      pc: str(['pc']),
      hhl: str(['hhl']),
      precinctNo: str(['precinct_no', 'precinct']) ?? '',
      isFlagged: asBool(json['is_flagged']),
      flagReason: json['flag_reason']?.toString(),
      isCoopMember: asBool(json['is_coop_member']),
      matchedMemberId: json['matched_member_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'voter_id': voterId,
        'firstname': firstname,
        'lastname': lastname,
        if (middlename != null) 'middlename': middlename,
        'barangay': barangay,
        'precinct_no': precinctNo,
        'is_flagged': isFlagged,
        if (flagReason != null) 'flag_reason': flagReason,
        'is_coop_member': isCoopMember,
        if (matchedMemberId != null) 'matched_member_id': matchedMemberId,
      };
}

class VoterSearchResult {
  final String id;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String lgu;
  final String barangay;
  final String? purok;
  final String status;
  final bool isVoter;
  final bool isCoopMember;
  final String? contactNumber;
  final String? birthDate;
  final String? membershipDate;
  final String? sector;
  final bool trucareMember;
  final bool phicMember;
  final String? phicNo;
  final int? voterId;
  final String? precinctNo;
  final String? householdId;

  VoterSearchResult({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName,
    required this.lgu,
    required this.barangay,
    this.purok,
    this.status = 'MEMBER',
    this.isVoter = true,
    this.isCoopMember = true,
    this.contactNumber,
    this.birthDate,
    this.membershipDate,
    this.sector,
    this.trucareMember = false,
    this.phicMember = false,
    this.phicNo,
    this.voterId,
    this.precinctNo,
    this.householdId,
  });

  String get fullName => '$lastName, $firstName${middleName != null && middleName!.isNotEmpty ? ' $middleName' : ''}';

  factory VoterSearchResult.fromFamilyMember(Map<String, dynamic> json) => VoterSearchResult(
        id: json['id']?.toString() ?? '',
        lastName: json['lastname']?.toString() ?? '',
        firstName: json['firstname']?.toString() ?? '',
        middleName: json['middlename']?.toString(),
        lgu: json['lgu']?.toString() ?? 'VALENCIA CITY',
        barangay: json['barangay']?.toString() ?? 'POBLACION',
        purok: json['purok']?.toString() ?? 'P-1',
        status: json['listing_status']?.toString().isNotEmpty == true
            ? json['listing_status'].toString()
            : (asBool(json['is_voter']) ? 'MEMBER' : 'RESIDENT'),
        isVoter: asBool(json['is_voter']),
        isCoopMember: asBool(json['is_cooperative_member']),
        contactNumber: json['contact_number']?.toString(),
        birthDate: json['birth_date']?.toString(),
        membershipDate: json['membership_date']?.toString(),
        sector: json['sector']?.toString() ?? 'General',
        trucareMember: asBool(json['trucare_member']),
        phicMember: asBool(json['phic_member']),
        phicNo: json['phic_no']?.toString(),
        voterId: (json['voter_id'] as num?)?.toInt(),
        precinctNo: json['precinct_no']?.toString() ?? (json['voter_id'] != null ? 'P-${json['voter_id']}' : null),
        householdId: json['household_id']?.toString(),
      );

  /// Maps a raw `voters` row. Optional columns (lgu, purok, birth_date, …) are read when present.
  factory VoterSearchResult.fromVoterRow(Map<String, dynamic> json) {
    String? str(String key) {
      final v = json[key]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final voterId = (json['voter_id'] as num?)?.toInt();
    final isCoopMember = asBool(json['is_coop_member']) || json['matched_member_id'] != null;
    return VoterSearchResult(
      id: json['id']?.toString() ?? '',
      lastName: str('lastname') ?? '',
      firstName: str('firstname') ?? '',
      middleName: str('middlename'),
      lgu: str('lgu') ?? 'VALENCIA CITY',
      barangay: str('brgy') ?? str('barangay') ?? '',
      purok: str('purok'),
      status: str('listing_status') ?? str('status') ?? 'MEMBER',
      isVoter: true,
      isCoopMember: isCoopMember,
      contactNumber: str('contact_number'),
      birthDate: str('birth_date') ?? str('birthdate'),
      sector: str('sector'),
      voterId: voterId,
      precinctNo: str('precinct_no') ?? str('precinct') ?? (voterId != null ? 'P-$voterId' : null),
    );
  }

  factory VoterSearchResult.fromVoter(Voter v) => VoterSearchResult(
        id: v.id,
        lastName: v.lastname,
        firstName: v.firstname,
        middleName: v.middlename,
        lgu: 'VALENCIA CITY',
        barangay: v.barangay,
        purok: 'P-1',
        status: 'MEMBER',
        isVoter: true,
        isCoopMember: v.isCoopMember,
        voterId: v.voterId,
        precinctNo: v.precinctNo,
      );
}

// ==========================================
// 7. FormTracking
// ==========================================
/// Statuses allowed by the `form_tracking_status_check` constraint.
class FormTrackingStatus {
  static const pending = 'Pending';
  static const inProgress = 'In Progress';
  static const completed = 'Completed';
  static const returned = 'Returned';

  static const all = [pending, inProgress, completed, returned];
}

/// A `form_tracking` row: one submission of physical forms for a barangay purok.
/// [encodedBy] and [returnedReleasedBy] are `users.id`s.
class FormTracking {
  final String id;
  final String barangay;
  final String purok;
  final int numberOfForms;
  final String submittedBy;
  final String receivedBy;
  final String? encodedBy;
  final String status;
  final String? returnedReleasedBy;
  final String? returnedReceivedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  FormTracking({
    required this.id,
    required this.barangay,
    required this.purok,
    required this.numberOfForms,
    required this.submittedBy,
    required this.receivedBy,
    this.encodedBy,
    this.status = FormTrackingStatus.pending,
    this.returnedReleasedBy,
    this.returnedReceivedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormTracking.fromJson(Map<String, dynamic> json) => FormTracking(
        id: json['id']?.toString() ?? '',
        barangay: json['barangay']?.toString() ?? '',
        purok: json['purok']?.toString() ?? '',
        numberOfForms: (json['number_of_forms'] as num?)?.toInt() ?? 0,
        submittedBy: json['submitted_by']?.toString() ?? '',
        receivedBy: json['received_by']?.toString() ?? '',
        encodedBy: _nonEmpty(json['encoded_by']),
        status: json['status']?.toString() ?? FormTrackingStatus.pending,
        returnedReleasedBy: _nonEmpty(json['returned_released_by']),
        returnedReceivedBy: _nonEmpty(json['returned_received_by']),
        createdAt: json['created_at'] != null ? parsePh(json['created_at'].toString()) ?? phNow() : phNow(),
        updatedAt: json['updated_at'] != null ? parsePh(json['updated_at'].toString()) ?? phNow() : phNow(),
      );

  /// [clearReturned] drops the returned-by fields, e.g. when a row leaves the Returned stage.
  FormTracking copyWith({
    String? barangay,
    String? purok,
    int? numberOfForms,
    String? submittedBy,
    String? receivedBy,
    String? encodedBy,
    String? status,
    String? returnedReleasedBy,
    String? returnedReceivedBy,
    DateTime? updatedAt,
    bool clearReturned = false,
  }) =>
      FormTracking(
        id: id,
        barangay: barangay ?? this.barangay,
        purok: purok ?? this.purok,
        numberOfForms: numberOfForms ?? this.numberOfForms,
        submittedBy: submittedBy ?? this.submittedBy,
        receivedBy: receivedBy ?? this.receivedBy,
        encodedBy: encodedBy ?? this.encodedBy,
        status: status ?? this.status,
        returnedReleasedBy: clearReturned ? null : returnedReleasedBy ?? this.returnedReleasedBy,
        returnedReceivedBy: clearReturned ? null : returnedReceivedBy ?? this.returnedReceivedBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String? _nonEmpty(Object? v) {
    final s = v?.toString();
    return s == null || s.isEmpty ? null : s;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barangay': barangay,
        'purok': purok,
        'number_of_forms': numberOfForms,
        'submitted_by': submittedBy,
        'received_by': receivedBy,
        'encoded_by': encodedBy,
        'status': status,
        'returned_released_by': returnedReleasedBy,
        'returned_received_by': returnedReceivedBy,
        'created_at': toPhIso(createdAt),
        'updated_at': toPhIso(updatedAt),
      };
}

// ==========================================
// 8. ActivityLog
// ==========================================
class ActivityLog {
  final String id;
  final String? userId;
  final String userName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString(),
        userName: json['user_name']?.toString() ?? 'System',
        action: json['action']?.toString() ?? 'UNKNOWN',
        entityType: json['entity_type']?.toString() ?? 'General',
        entityId: json['entity_id']?.toString(),
        details: json['details'] is Map<String, dynamic>
            ? json['details'] as Map<String, dynamic>
            : (json['details'] is String ? tryParseJson(json['details'] as String) : null),
        createdAt: json['created_at'] != null ? parsePh(json['created_at'].toString()) ?? phNow() : phNow(),
      );

  static Map<String, dynamic>? tryParseJson(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        'user_name': userName,
        'action': action,
        'entity_type': entityType,
        if (entityId != null) 'entity_id': entityId,
        if (details != null) 'details': details,
        'created_at': toPhIso(createdAt),
      };
}
