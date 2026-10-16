# TROPA v2 (Tabang Respeto Og Panalipud)
## Cross-Platform Flutter Desktop & Web Application Architecture

### 1. `pubspec.yaml`
```yaml
name: tropa_v2
description: Community & Cooperative Management System (Tabang Respeto Og Panalipud)
version: 2.0.0+1
environment:
  sdk: ">=3.2.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Routing & Deep Linking
  go_router: ^13.2.0

  # State Management & DI
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Backend, Authentication & Storage
  supabase_flutter: ^2.3.4

  # Interactive Maps (Web, Windows, macOS, Linux)
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # Forms, Builders & Validation
  flutter_form_builder: ^9.2.1
  form_builder_validators: ^9.1.0

  # Data Tables & Pagination
  data_table_2: ^2.5.12

  # Utilities & Formatting
  intl: ^0.19.0
  uuid: ^4.3.3
  file_picker: ^8.0.0
  csv: ^5.1.1
  pdf: ^3.10.8
  printing: ^5.12.0
  google_fonts: ^6.1.0
  shared_preferences: ^2.2.2
  cached_network_image: ^3.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.10
```

---

### 2. Design System & Theme Provider (`theme_provider.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadPreference();
  }

  static const _prefKey = 'theme_mode_preference';

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'light') state = ThemeMode.light;
    if (saved == 'dark') state = ThemeMode.dark;
    if (saved == 'system') state = ThemeMode.system;
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, next == ThemeMode.dark ? 'dark' : 'light');
  }
}

class TropaTheme {
  // Light Theme Tokens
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1E3A8A), // Deep Blue
      onPrimary: Colors.white,
      secondary: Color(0xFF0284C7),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF8FAFC), // Off-white clean slate
      surfaceVariant: Color(0xFFF1F5F9),
      outline: Color(0xFFCBD5E1),
      error: Color(0xFFDC2626),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
  );

  // Dark Theme Tokens
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38BDF8), // Soft Blue Accent
      onPrimary: Color(0xFF0F172A),
      secondary: Color(0xFF94A3B8),
      surface: Color(0xFF1E293B), // Elevated dark slate
      background: Color(0xFF0F172A), // Deep Slate
      surfaceVariant: Color(0xFF273549),
      outline: Color(0xFF334155),
      error: Color(0xFFF87171),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardTheme: CardTheme(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
  );
}
```

---

### 3. Data Models (`models.dart`)

All timestamps are GMT+8 (Asia/Manila), whatever the device timezone: write with `toPhIso`, read with `parsePh`, display with `formatPh` (see `lib/core/ph_time.dart`).
```dart
import 'dart:convert';

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
    required this.createdDate,
    required this.updatedDate,
    required this.createdBy,
  });

  factory Household.fromJson(Map<String, dynamic> json) => Household(
    id: json['id'] as String,
    householdName: json['household_name'] as String,
    lgu: json['lgu'] as String,
    barangay: json['barangay'] as String,
    purok: json['purok'] as String,
    purokId: json['purok_id'] as String?,
    householdLeaderId: json['household_leader_id'] as String?,
    totalMembers: json['total_members'] as int? ?? 0,
    activeMembers: json['active_members'] as int? ?? 0,
    status: json['status'] as String? ?? 'active',
    housePictureUrl: json['house_picture_url'] as String?,
    housePicturePath: json['house_picture_path'] as String?,
    createdDate: parsePh(json['created_date'] as String)!,
    updatedDate: parsePh(json['updated_date'] as String)!,
    createdBy: json['created_by'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'household_name': householdName,
    'lgu': lgu,
    'barangay': barangay,
    'purok': purok,
    'purok_id': purokId,
    'household_leader_id': householdLeaderId,
    'total_members': totalMembers,
    'active_members': activeMembers,
    'status': status,
    'house_picture_url': housePictureUrl,
    'house_picture_path': housePicturePath,
    'created_date': toPhIso(createdDate),
    'updated_date': toPhIso(updatedDate),
    'created_by': createdBy,
  };
}

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
  final String? listingStatus;
  final String? profilePictureUrl;
  final String? profilePicturePath;
  final bool? phicMember;
  final String? phicNo;
  final bool? trucareMember;
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
    this.listingStatus,
    this.profilePictureUrl,
    this.profilePicturePath,
    this.phicMember,
    this.phicNo,
    this.trucareMember,
    required this.createdDate,
    required this.updatedDate,
    this.createdBy,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    householdId: json['household_id'] as String,
    firstname: json['firstname'] as String,
    lastname: json['lastname'] as String,
    middlename: json['middlename'] as String?,
    extension: json['extension'] as String?,
    lgu: json['lgu'] as String,
    barangay: json['barangay'] as String,
    purok: json['purok'] as String,
    purokId: json['purok_id'] as String?,
    sector: json['sector'] as String? ?? 'General',
    isVoter: json['is_voter'] as bool? ?? false,
    voterBarangay: json['voter_barangay'] as String?,
    voterId: json['voter_id'] as int?,
    contactNumber: json['contact_number'] as String?,
    isHouseholdLeader: json['is_household_leader'] as bool? ?? false,
    isCooperativeMember: json['is_cooperative_member'] as bool? ?? false,
    membershipDate: json['membership_date'] != null ? parsePh(json['membership_date'] as String)! : null,
    birthDate: json['birth_date'] != null ? parsePh(json['birth_date'] as String)! : null,
    age: json['age'] as int?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    religion: json['religion'] as String?,
    school: json['school'] as String?,
    yearLevel: json['year_level'] as String?,
    listingStatus: json['listing_status'] as String?,
    profilePictureUrl: json['profile_picture_url'] as String?,
    profilePicturePath: json['profile_picture_path'] as String?,
    phicMember: json['phic_member'] as bool?,
    phicNo: json['phic_no'] as String?,
    trucareMember: json['trucare_member'] as bool?,
    createdDate: parsePh(json['created_date'] as String)!,
    updatedDate: parsePh(json['updated_date'] as String)!,
    createdBy: json['created_by'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'household_id': householdId,
    'firstname': firstname,
    'lastname': lastname,
    'middlename': middlename,
    'extension': extension,
    'lgu': lgu,
    'barangay': barangay,
    'purok': purok,
    'purok_id': purokId,
    'sector': sector,
    'is_voter': isVoter,
    'voter_barangay': voterBarangay,
    'voter_id': voterId,
    'contact_number': contactNumber,
    'is_household_leader': isHouseholdLeader,
    'is_cooperative_member': isCooperativeMember,
    'membership_date': membershipDate?.toIso8601String(),
    'birth_date': birthDate?.toIso8601String(),
    'age': age,
    'latitude': latitude,
    'longitude': longitude,
    'religion': religion,
    'school': school,
    'year_level': yearLevel,
    'listing_status': listingStatus,
    'profile_picture_url': profilePictureUrl,
    'profile_picture_path': profilePicturePath,
    'phic_member': phicMember,
    'phic_no': phicNo,
    'trucare_member': trucareMember,
    'created_date': toPhIso(createdDate),
    'updated_date': toPhIso(updatedDate),
    'created_by': createdBy,
  };
}

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
  });

  factory DuesPayment.fromJson(Map<String, dynamic> json) => DuesPayment(
    id: json['id'] as String,
    memberId: json['member_id'] as String,
    householdId: json['household_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    paymentMonth: json['payment_month'] as String,
    monthsCovered: json['months_covered'] as int?,
    paymentDate: parsePh(json['payment_date'] as String)!,
    paymentMethod: json['payment_method'] as String,
    referenceNumber: json['reference_number'] as String?,
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'completed',
    collectedBy: json['collected_by'] as String? ?? '',
    createdBy: json['created_by'] as String? ?? '',
    createdDate: parsePh(json['created_date'] as String)!,
    updatedDate: parsePh(json['updated_date'] as String)!,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'member_id': memberId,
    'household_id': householdId,
    'amount': amount,
    'payment_month': paymentMonth,
    'months_covered': monthsCovered,
    'payment_date': toPhIso(paymentDate),
    'payment_method': paymentMethod,
    'reference_number': referenceNumber,
    'notes': notes,
    'status': status,
    'collected_by': collectedBy,
    'created_by': createdBy,
    'created_date': toPhIso(createdDate),
    'updated_date': toPhIso(updatedDate),
  };
}

class AppUser {
  final String id;
  final String email;
  final String firstname;
  final String lastname;
  final String role;
  final String status;
  final List<String> permissions;
  final DateTime? lastLogin;
  final DateTime createdDate;
  final DateTime updatedDate;

  AppUser({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.role,
    required this.status,
    required this.permissions,
    this.lastLogin,
    required this.createdDate,
    required this.updatedDate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    firstname: json['firstname'] as String? ?? '',
    lastname: json['lastname'] as String? ?? '',
    role: json['role'] as String? ?? 'user',
    status: json['status'] as String? ?? 'active',
    permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    lastLogin: json['last_login'] != null ? parsePh(json['last_login'] as String)! : null,
    createdDate: parsePh(json['created_date'] as String)!,
    updatedDate: parsePh(json['updated_date'] as String)!,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstname': firstname,
    'lastname': lastname,
    'role': role,
    'status': status,
    'permissions': permissions,
    'last_login': lastLogin?.toIso8601String(),
    'created_date': toPhIso(createdDate),
    'updated_date': toPhIso(updatedDate),
  };
}
```

---

### 4. Supabase Service with Auto-Activity Logging & Storage
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;
  static const uuid = Uuid();

  // Current session & user
  User? get currentUser => client.auth.currentUser;

  // Audit Logging Helper
  Future<void> logActivity({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = currentUser;
      await client.from('activity_log').insert({
        'id': uuid.v4(),
        'user_id': user?.id,
        'user_name': user?.email ?? 'System User',
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Non-blocking log catch
    }
  }

  // --- Households CRUD ---
  Future<List<Household>> getHouseholds({String? query, String? barangay}) async {
    var req = client.from('households').select();
    if (barangay != null && barangay.isNotEmpty) {
      req = req.eq('barangay', barangay);
    }
    if (query != null && query.isNotEmpty) {
      req = req.ilike('household_name', '%$query%');
    }
    final response = await req.order('created_date', ascending: false);
    return (response as List).map((row) => Household.fromJson(row)).toList();
  }

  Future<Household> createHousehold(Household item) async {
    final res = await client.from('households').insert(item.toJson()).select().single();
    await logActivity(
      action: 'ADD',
      entityType: 'Household',
      entityId: item.id,
      details: {'household_name': item.householdName, 'barangay': item.barangay},
    );
    return Household.fromJson(res);
  }

  // --- Members CRUD & Map Query ---
  Future<List<FamilyMember>> getMembers({String? query, String? barangay, String? sector}) async {
    var req = client.from('family_members').select();
    if (barangay != null && barangay.isNotEmpty) {
      req = req.eq('barangay', barangay);
    }
    if (sector != null && sector.isNotEmpty) {
      req = req.eq('sector', sector);
    }
    if (query != null && query.isNotEmpty) {
      req = req.or('firstname.ilike.%$query%,lastname.ilike.%$query%');
    }
    final response = await req.order('lastname', ascending: true);
    return (response as List).map((row) => FamilyMember.fromJson(row)).toList();
  }

  // --- Storage Upload Service ---
  Future<String?> uploadStorageFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }
}
```

---

### 5. `go_router` Role-Based Route Guarding
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GoRouter createTropaRouter(List<String> userPermissions) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (BuildContext context, GoRouterState state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isLogin = state.matchedLocation == '/login';
      final isPublicSearch = state.matchedLocation == '/search';

      if (!isAuth && !isLogin && !isPublicSearch) {
        return '/login';
      }
      if (isAuth && isLogin) {
        return '/dashboard';
      }

      // Check Granular RBAC Permissions
      bool can(String perm) =>
          userPermissions.contains('all') || userPermissions.contains(perm);

      final path = state.matchedLocation;
      if (path.startsWith('/households') && !can('view_households')) return '/dashboard';
      if (path.startsWith('/members') && !can('view_members')) return '/dashboard';
      if (path.startsWith('/dues') && !can('dues_collection')) return '/dashboard';
      if (path.startsWith('/reports') && !can('view_reports')) return '/dashboard';
      if ((path.startsWith('/form-tracking') || path.startsWith('/settings') || path.startsWith('/logs')) && !can('user_management')) {
        return '/dashboard';
      }
      if (path.startsWith('/tropa-finder') && !can('tropa_finder')) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/search', builder: (context, state) => const PublicSearchPage()),
      ShellRoute(
        builder: (context, state, child) => TropaDesktopScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardView()),
          GoRoute(path: '/households', builder: (context, state) => const HouseholdsView()),
          GoRoute(path: '/members', builder: (context, state) => const MembersView()),
          GoRoute(path: '/dues', builder: (context, state) => const DuesCollectionView()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsAnalyticsView()),
          GoRoute(path: '/form-tracking', builder: (context, state) => const FormTrackingView()),
          GoRoute(path: '/tropa-finder', builder: (context, state) => const TropaFinderView()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsAdminView()),
          GoRoute(path: '/logs', builder: (context, state) => const ActivityLogsView()),
        ],
      ),
    ],
  );
}
```
