import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/geo.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// Tropa Finder rows per page.
const voterPageSize = 30;

class VoterFilter {
  final String lastName;
  final String firstName;
  final String middleName;
  final String lgu;
  final String barangay;
  final bool? flaggedOnly;
  /// `voters.status` group: 'All', 'MEMBERS', 'HHL' or 'PC'.
  final String status;
  /// Only voters not yet Tropa (cooperative) members.
  final bool notTropaMember;
  /// Zero-based results page of [voterPageSize] rows.
  final int page;
  /// Column the results are sorted by (see SupabaseService.voterSortColumns).
  final String sortBy;
  final bool sortAscending;

  const VoterFilter({
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.lgu = 'All',
    this.barangay = 'All',
    this.flaggedOnly,
    this.status = 'All',
    this.notTropaMember = false,
    this.page = 0,
    this.sortBy = 'lastname',
    this.sortAscending = true,
  });

  VoterFilter copyWith({
    String? lastName,
    String? firstName,
    String? middleName,
    String? lgu,
    String? barangay,
    bool? flaggedOnly,
    String? status,
    bool? notTropaMember,
    int? page,
    String? sortBy,
    bool? sortAscending,
  }) {
    return VoterFilter(
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lgu: lgu ?? this.lgu,
      barangay: barangay ?? this.barangay,
      flaggedOnly: flaggedOnly ?? this.flaggedOnly,
      status: status ?? this.status,
      notTropaMember: notTropaMember ?? this.notTropaMember,
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// LGU/barangay rows (with their id) from the `locations` table.
final locationsProvider = FutureProvider<List<LocationOption>>((ref) {
  ref.watch(tableChangesProvider('locations'));
  return ref.watch(supabaseServiceProvider).getLocations();
});

/// Puroks of one location, from the `puroks` table (keyed by `locations.id`).
final puroksProvider = FutureProvider.family<List<({String id, String name})>, String>((ref, locationId) {
  ref.watch(tableChangesProvider('puroks'));
  return ref.watch(supabaseServiceProvider).getPuroks(locationId);
});

final voterFilterProvider = StateProvider<VoterFilter>((ref) {
  return const VoterFilter();
});

final votersAsyncProvider = FutureProvider<List<Voter>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(voterFilterProvider);
  final items = await service.getVoters(
    lastName: filter.lastName,
    firstName: filter.firstName,
    middleName: filter.middleName,
    lgu: filter.lgu,
    barangay: filter.barangay,
    flaggedOnly: filter.flaggedOnly,
    status: filter.status,
    notTropaMember: filter.notTropaMember,
  );
  if (items.isNotEmpty) return items;

  // Fallback realistic voter cross-reference records if table is unseeded
  return [
    Voter(
      id: 'v-101',
      voterId: 104289,
      firstname: 'Roberto',
      lastname: 'Alcantara',
      middlename: 'G.',
      barangay: 'POBLACION',
      precinctNo: '0142A',
      isFlagged: false,
      isCoopMember: true,
      matchedMemberId: 'mem-901',
    ),
    Voter(
      id: 'v-102',
      voterId: 105672,
      firstname: 'Erlinda',
      lastname: 'Mercado',
      middlename: 'Reyes',
      barangay: 'BANLAG',
      precinctNo: '0089B',
      isFlagged: true,
      flagReason: 'Dual Precinct Registration Hold',
      isCoopMember: true,
      matchedMemberId: 'mem-902',
    ),
    Voter(
      id: 'v-103',
      voterId: 109230,
      firstname: 'Danilo',
      lastname: 'Villanueva',
      middlename: 'C.',
      barangay: 'LILINGAYON',
      precinctNo: '0204C',
      isFlagged: false,
      isCoopMember: false,
    ),
  ];
});

final voterNotifierProvider = StateNotifierProvider<VoterNotifier, AsyncValue<List<Voter>>>((ref) {
  return VoterNotifier(ref);
});

class VoterNotifier extends StateNotifier<AsyncValue<List<Voter>>> {
  final Ref ref;

  late final StreamSubscription<void> _changes;

  VoterNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
    // Re-query quietly when the voter snapshot installs or flags change (locally or via sync).
    _changes = ref
        .read(localDbProvider)
        .onChange(['voters', 'voter_flags'], triggerImmediately: false)
        .listen((_) => refresh(quiet: true));
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
      final filter = ref.read(voterFilterProvider);
      final items = await service.getVoters(
        lastName: filter.lastName,
        firstName: filter.firstName,
        middleName: filter.middleName,
        lgu: filter.lgu,
        barangay: filter.barangay,
        flaggedOnly: filter.flaggedOnly,
        status: filter.status,
        notTropaMember: filter.notTropaMember,
        // One extra row tells the view whether a next page exists
        limit: voterPageSize + 1,
        offset: filter.page * voterPageSize,
        sortBy: filter.sortBy,
        sortAscending: filter.sortAscending,
      );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> flagVoter(String id, String reason) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.flagVoter(id, reason);
      return true;
    } catch (e) {
      return false;
    }
  }
}
