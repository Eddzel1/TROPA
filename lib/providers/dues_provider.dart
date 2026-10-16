import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import '../core/ph_time.dart';
import 'auth_provider.dart';

class DuesFilter {
  final String query;
  final String? memberId;
  final String? householdId;
  final int page;

  const DuesFilter({
    this.query = '',
    this.memberId,
    this.householdId,
    this.page = 0,
  });

  DuesFilter copyWith({
    String? query,
    String? memberId,
    String? householdId,
    int? page,
  }) {
    return DuesFilter(
      query: query ?? this.query,
      memberId: memberId ?? this.memberId,
      householdId: householdId ?? this.householdId,
      page: page ?? this.page,
    );
  }
}

final duesFilterProvider = StateProvider<DuesFilter>((ref) {
  return const DuesFilter();
});

final duesAsyncProvider = FutureProvider<List<DuesPayment>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(duesFilterProvider);
  final items = await service.getDuesPayments(
    query: filter.query,
    memberId: filter.memberId,
    householdId: filter.householdId,
    page: filter.page,
  );
  if (items.isNotEmpty) return items;

  // Fallback demo ledger data if newly provisioned database has 0 payments
  return [
    DuesPayment(
      id: 'dues-demo-1',
      memberId: 'm-01',
      householdId: 'hh-01',
      amount: 250.00,
      paymentMonth: '2026-03',
      monthsCovered: 1,
      paymentDate: phNow().subtract(const Duration(days: 2)),
      paymentMethod: 'GCash',
      referenceNumber: 'GCASH-9842109',
      status: 'completed',
      collectedBy: 'R. Del Rosario',
      createdBy: 'Admin',
      createdDate: phNow().subtract(const Duration(days: 2)),
      updatedDate: phNow().subtract(const Duration(days: 2)),
    ),
    DuesPayment(
      id: 'dues-demo-2',
      memberId: 'm-02',
      householdId: 'hh-02',
      amount: 500.00,
      paymentMonth: '2026-02 to 2026-03',
      monthsCovered: 2,
      paymentDate: phNow().subtract(const Duration(days: 5)),
      paymentMethod: 'Cash',
      referenceNumber: 'OR-772184',
      status: 'completed',
      collectedBy: 'M. Bautista',
      createdBy: 'Admin',
      createdDate: phNow().subtract(const Duration(days: 5)),
      updatedDate: phNow().subtract(const Duration(days: 5)),
    ),
  ];
});

final duesListNotifierProvider = StateNotifierProvider<DuesListNotifier, AsyncValue<List<DuesPayment>>>((ref) {
  return DuesListNotifier(ref);
});

class DuesListNotifier extends StateNotifier<AsyncValue<List<DuesPayment>>> {
  final Ref ref;

  late final StreamSubscription<void> _changes;

  DuesListNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
    // Re-query quietly when local edits or synced rows touch this table.
    _changes = ref.read(localDbProvider).onChange(['dues_payments'], triggerImmediately: false).listen((_) => refresh(quiet: true));
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
      final filter = ref.read(duesFilterProvider);
      final list = await service.getDuesPayments(
        query: filter.query,
        memberId: filter.memberId,
        householdId: filter.householdId,
        page: filter.page,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> recordPayment(DuesPayment item) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.createDuesPayment(item);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePayment(String id) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.deleteDuesPayment(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
