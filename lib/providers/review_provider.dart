import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../services/review_flags.dart';
import 'auth_provider.dart';

/// Filters of the For Review page.
class ReviewFilter {
  /// 'All', 'household' or 'member'.
  final String kind;

  /// A [ReviewFlags] key, or 'All'.
  final String flag;
  final String lgu;
  final String barangay;
  final String query;

  /// Also list records whose problems were all cleared (to restore them).
  final bool showCleared;

  const ReviewFilter({
    this.kind = 'All',
    this.flag = 'All',
    this.lgu = 'All',
    this.barangay = 'All',
    this.query = '',
    this.showCleared = false,
  });

  ReviewFilter copyWith({String? kind, String? flag, String? lgu, String? barangay, String? query, bool? showCleared}) =>
      ReviewFilter(
        kind: kind ?? this.kind,
        flag: flag ?? this.flag,
        lgu: lgu ?? this.lgu,
        barangay: barangay ?? this.barangay,
        query: query ?? this.query,
        showCleared: showCleared ?? this.showCleared,
      );

  /// Whether [item] passes every filter except [flag] (used to count items per problem).
  bool matchesExceptFlag(ReviewItem item) {
    if (!showCleared && item.fullyCleared) return false;
    if (kind != 'All' && item.entityType != kind) return false;
    if (lgu != 'All' && item.lgu.toUpperCase() != lgu.toUpperCase()) return false;
    if (barangay != 'All' && item.barangay.toUpperCase() != barangay.toUpperCase()) return false;
    final q = query.trim().toUpperCase();
    if (q.isNotEmpty && !item.title.contains(q) && !item.householdName.contains(q)) return false;
    return true;
  }

  bool matches(ReviewItem item) {
    if (!matchesExceptFlag(item)) return false;
    if (flag == 'All') return true;
    // Hidden problems don't count unless cleared ones are shown.
    return item.flags.any((f) => f.key == flag && (showCleared || !f.cleared));
  }
}

final reviewFilterProvider = StateProvider<ReviewFilter>((ref) => const ReviewFilter());

final reviewItemsProvider = StateNotifierProvider<ReviewItemsNotifier, AsyncValue<List<ReviewItem>>>((ref) {
  return ReviewItemsNotifier(ref);
});

/// Every flagged record on this device. Recomputed (quietly) a moment after members, households
/// or cleared problems change, so a fix made from the page drops the record from the list.
class ReviewItemsNotifier extends StateNotifier<AsyncValue<List<ReviewItem>>> {
  final Ref ref;
  late final StreamSubscription<void> _changes;
  Timer? _debounce;

  ReviewItemsNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
    _changes = ref
        .read(localDbProvider)
        .onChange(['family_members', 'households', 'review_dismissals'], triggerImmediately: false)
        .listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), () => refresh(quiet: true));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _changes.cancel();
    super.dispose();
  }

  /// [quiet] keeps the current list on screen instead of a loading state.
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet || !state.hasValue) state = const AsyncValue.loading();
    try {
      final items = await ref.read(supabaseServiceProvider).getReviewItems();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> clear(ReviewItem item, {String? note}) async {
    await ref.read(supabaseServiceProvider).clearReview(item, note: note);
    await refresh(quiet: true);
  }

  Future<void> restore(ReviewItem item) async {
    await ref.read(supabaseServiceProvider).restoreReview(item);
    await refresh(quiet: true);
  }
}
