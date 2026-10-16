import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

class MemberFilter {
  final String query;
  final String lastName;
  final String firstName;
  final String middleName;
  final String lgu;
  final String barangay;
  final String sector;
  final String listingStatus;
  final bool? isCooperativeMember;
  final String? householdId;
  final int page;

  const MemberFilter({
    this.query = '',
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.lgu = 'All',
    this.barangay = 'All',
    this.sector = 'All',
    this.listingStatus = 'All',
    this.isCooperativeMember,
    this.householdId,
    this.page = 0,
  });

  /// Pass `clearHousehold: true` to reset the household filter back to "All Households".
  MemberFilter copyWith({
    String? query,
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    String? sector,
    String? listingStatus,
    bool? isCooperativeMember,
    String? householdId,
    bool clearHousehold = false,
    int? page,
  }) {
    return MemberFilter(
      query: query ?? this.query,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lgu: lgu ?? this.lgu,
      barangay: barangay ?? this.barangay,
      sector: sector ?? this.sector,
      listingStatus: listingStatus ?? this.listingStatus,
      isCooperativeMember: isCooperativeMember ?? this.isCooperativeMember,
      householdId: clearHousehold ? null : (householdId ?? this.householdId),
      page: page ?? this.page,
    );
  }
}

/// Rows shown per load on the Members page.
const memberPageSize = 100;

/// (matching the current filters, all members) — shown under the Members page filters.
final memberCountsProvider = StateProvider<({int matched, int total})>((ref) => (matched: 0, total: 0));

final memberFilterProvider = StateProvider<MemberFilter>((ref) {
  return const MemberFilter();
});

final membersAsyncProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(memberFilterProvider);
  return service.getMembers(
    query: filter.query,
    barangay: filter.barangay == 'All' ? null : filter.barangay,
    sector: filter.sector == 'All' ? null : filter.sector,
    isCoopMember: filter.isCooperativeMember,
    householdId: filter.householdId,
    page: filter.page,
    pageSize: 50,
  );
});

final memberListNotifierProvider = StateNotifierProvider<MemberListNotifier, AsyncValue<List<FamilyMember>>>((ref) {
  return MemberListNotifier(ref);
});

class MemberListNotifier extends StateNotifier<AsyncValue<List<FamilyMember>>> {
  final Ref ref;

  late final StreamSubscription<void> _changes;

  MemberListNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
    // Re-query quietly when local edits or synced rows touch this table.
    _changes = ref.read(localDbProvider).onChange(['family_members'], triggerImmediately: false).listen((_) => refresh(quiet: true));
  }

  @override
  void dispose() {
    _changes.cancel();
    super.dispose();
  }

  /// [quiet] keeps the current rows on screen instead of flashing a loading state.
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet || !state.hasValue) state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final filter = ref.read(memberFilterProvider);
      final results = await Future.wait([
        service.getMembersWithCount(
          query: filter.query,
          lastName: filter.lastName,
          firstName: filter.firstName,
          middleName: filter.middleName,
          lgu: filter.lgu,
          barangay: filter.barangay,
          sector: filter.sector,
          listingStatus: filter.listingStatus,
          isCoopMember: filter.isCooperativeMember,
          householdId: filter.householdId,
          page: filter.page,
          pageSize: memberPageSize,
        ),
        service.countAllMembers(),
      ]);
      // Ignore stale responses if the filters changed while this request was in flight
      if (!identical(filter, ref.read(memberFilterProvider))) return;
      final page = results[0] as ({List<FamilyMember> members, int matchCount});
      ref.read(memberCountsProvider.notifier).state = (matched: page.matchCount, total: results[1] as int);
      state = AsyncValue.data(page.members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FamilyMember?> addMember(FamilyMember item) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      final created = await service.createMember(item);
      return created;
    } catch (e) {
      return null;
    }
  }

  Future<List<FamilyMember>> addMembersBulk(List<FamilyMember> items) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      final created = await service.createFamilyMembersBulk(items);
      return created;
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateMember(FamilyMember item) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.updateMember(item);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns whether the member's old household was deleted; throws if the transfer failed.
  Future<bool> transferMember(String memberId, String targetHouseholdId) {
    final service = ref.read(supabaseServiceProvider);
    return service.transferMember(memberId: memberId, targetHouseholdId: targetHouseholdId);
  }

  Future<bool> deleteMember(String id) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.deleteMember(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
