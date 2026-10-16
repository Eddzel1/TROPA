import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

class FormTrackingFilter {
  final String query;
  final String status;
  final String lgu;
  final String barangay;

  /// Submission date order: [newestFirst] or [oldestFirst].
  final String sort;

  static const newestFirst = 'Newest first';
  static const oldestFirst = 'Oldest first';

  const FormTrackingFilter({
    this.query = '',
    this.status = 'All',
    this.lgu = 'All',
    this.barangay = 'All',
    this.sort = newestFirst,
  });

  FormTrackingFilter copyWith({
    String? query,
    String? status,
    String? lgu,
    String? barangay,
    String? sort,
  }) {
    return FormTrackingFilter(
      query: query ?? this.query,
      status: status ?? this.status,
      lgu: lgu ?? this.lgu,
      barangay: barangay ?? this.barangay,
      sort: sort ?? this.sort,
    );
  }
}

final formTrackingFilterProvider = StateProvider<FormTrackingFilter>((ref) {
  return const FormTrackingFilter();
});

final formBatchNotifierProvider = StateNotifierProvider<FormBatchNotifier, AsyncValue<List<FormTracking>>>((ref) {
  return FormBatchNotifier(ref);
});

class FormBatchNotifier extends StateNotifier<AsyncValue<List<FormTracking>>> {
  final Ref ref;

  late final StreamSubscription<void> _changes;

  FormBatchNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
    // Re-query quietly when local edits or synced rows touch this table.
    _changes = ref.read(localDbProvider).onChange(['form_tracking'], triggerImmediately: false).listen((_) => refresh(quiet: true));
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
      final filter = ref.read(formTrackingFilterProvider);
      final items = await service.getFormBatches(
        query: filter.query,
        status: filter.status == 'All' ? null : filter.status,
        lgu: filter.lgu == 'All' ? null : filter.lgu,
        barangay: filter.barangay == 'All' ? null : filter.barangay,
        oldestFirst: filter.sort == FormTrackingFilter.oldestFirst,
      );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Saves several submissions (one per purok) in a single transaction.
  Future<bool> createBatches(List<FormTracking> batches) async {
    try {
      await ref.read(supabaseServiceProvider).createFormBatches(batches);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBatch(String id) async {
    try {
      await ref.read(supabaseServiceProvider).deleteFormBatch(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Moves a submission to another pipeline stage. The card switches columns right away;
  /// on failure the list is reloaded to put it back.
  Future<bool> moveBatch(FormTracking batch, String status) async {
    final moved = batch.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      clearReturned: status != FormTrackingStatus.returned,
    );
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data([for (final b in current) b.id == batch.id ? moved : b]);
    }
    final ok = await updateBatch(moved);
    if (!ok) await refresh(quiet: true);
    return ok;
  }

  Future<bool> updateBatch(FormTracking batch) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.updateFormBatch(batch);
      return true;
    } catch (e) {
      return false;
    }
  }
}
