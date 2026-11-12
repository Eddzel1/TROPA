import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

class HouseholdFilter {
  final String query;
  final String lgu;
  final String barangay;
  final String purok;

  /// Show archived households instead of active ones.
  final bool archived;
  final int page;

  const HouseholdFilter({
    this.query = '',
    this.lgu = 'All',
    this.barangay = 'All',
    this.purok = 'All',
    this.archived = false,
    this.page = 0,
  });

  HouseholdFilter copyWith({
    String? query,
    String? lgu,
    String? barangay,
    String? purok,
    bool? archived,
    int? page,
  }) {
    return HouseholdFilter(
      query: query ?? this.query,
      lgu: lgu ?? this.lgu,
      barangay: barangay ?? this.barangay,
      purok: purok ?? this.purok,
      archived: archived ?? this.archived,
      page: page ?? this.page,
    );
  }
}

final householdFilterProvider = StateProvider<HouseholdFilter>((ref) {
  return const HouseholdFilter();
});

/// Rows per page on the Households page.
const householdPageSize = 50;

/// Households matching the current filters, across all pages, for the pager.
final householdMatchCountProvider = StateProvider<int>((ref) => 0);

final householdsAsyncProvider = FutureProvider<List<Household>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(householdFilterProvider);
  return service.getHouseholds(
    query: filter.query,
    lgu: filter.lgu == 'All' ? null : filter.lgu,
    barangay: filter.barangay == 'All' ? null : filter.barangay,
    purok: filter.purok == 'All' ? null : filter.purok,
    page: filter.page,
    pageSize: 50,
  );
});

/// Households with coordinates, one pin each on the dashboard map.
/// Throttled so a sync burst re-queries at most every 2 s instead of once per batch.
final householdCoordinatesProvider = StreamProvider<List<Household>>((ref) {
  return ref
      .watch(localDbProvider)
      .watch(
        'SELECT * FROM households WHERE latitude IS NOT NULL AND longitude IS NOT NULL',
        throttle: const Duration(seconds: 2),
      )
      .map((rows) => rows.map(Household.fromJson).toList());
});

final householdListNotifierProvider = StateNotifierProvider<HouseholdListNotifier, AsyncValue<List<Household>>>((ref) {
  return HouseholdListNotifier(ref);
});

class HouseholdListNotifier extends StateNotifier<AsyncValue<List<Household>>> {
  final Ref ref;

  late final StreamSubscription<void> _changes;

  HouseholdListNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
    // Re-query quietly when local edits or synced rows touch this table.
    _changes = ref
        .read(localDbProvider)
        .onChange(['households'], triggerImmediately: false).listen((_) => refresh(quiet: true));
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
      final filter = ref.read(householdFilterProvider);
      final result = await service.getHouseholdsWithCount(
        query: filter.query,
        lgu: filter.lgu == 'All' ? null : filter.lgu,
        barangay: filter.barangay == 'All' ? null : filter.barangay,
        purok: filter.purok == 'All' ? null : filter.purok,
        archived: filter.archived,
        page: filter.page,
        pageSize: householdPageSize,
      );
      // Ignore stale responses if the filters changed while this request was in flight
      if (!identical(filter, ref.read(householdFilterProvider))) return;
      // The last page emptied (e.g. its last household was archived): step back to the new last page.
      if (result.households.isEmpty && filter.page > 0 && result.matchCount > 0) {
        ref.read(householdFilterProvider.notifier).state =
            filter.copyWith(page: (result.matchCount - 1) ~/ householdPageSize);
        await refresh(quiet: quiet);
        return;
      }
      ref.read(householdMatchCountProvider.notifier).state = result.matchCount;
      state = AsyncValue.data(result.households);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Household?> addHousehold(Household item) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      final created = await service.createHousehold(item);
      return created;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateHousehold(Household item) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.updateHousehold(item);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setHouseholdArchived(Household household, bool archived) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.setHouseholdArchived(household, archived);
      return true;
    } catch (e) {
      return false;
    }
  }
}
