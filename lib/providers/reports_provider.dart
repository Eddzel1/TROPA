import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// Fires when report source tables change, throttled so a sync burst triggers one recompute.
final _reportSourceChangesProvider = StreamProvider<void>((ref) {
  final db = ref.watch(localDbProvider);
  return db.onChange(
    ['households', 'family_members', 'locations'],
    throttle: const Duration(seconds: 2),
    triggerImmediately: false,
  );
});

/// Per-barangay counts for every LGU. Kept alive (not autoDispose), so revisiting Reports reuses
/// the cached result; it only recomputes when the source tables change.
final barangayReportProvider = FutureProvider<List<BarangayStat>>((ref) {
  ref.watch(_reportSourceChangesProvider);
  return ref.watch(supabaseServiceProvider).getBarangayReportStats();
});

/// LGU selected in the Reports table ('All' = every LGU). Filtering is done in memory.
final reportLguFilterProvider = StateProvider<String>((ref) => 'All');
