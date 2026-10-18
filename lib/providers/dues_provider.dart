import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// Tables whose changes can move a dues balance or the ledger.
const _duesTables = 'dues_payments,family_members,households,locations';

/// The barangays the signed-in user collects dues for.
final duesScopeProvider = FutureProvider<DuesScope>((ref) async {
  ref.watch(tableChangesProvider('locations'));
  final user = ref.watch(currentAppUserProvider).value;
  if (user == null) return const DuesScope();
  return ref.watch(supabaseServiceProvider).getDuesScope(user);
});

/// Every dues rate, oldest effective month first. Live.
final duesRatesProvider = StreamProvider<List<DuesRate>>((ref) {
  return ref.watch(supabaseServiceProvider).watchDuesRates();
});

enum DuesSearchMode { household, member }

class DuesSearch {
  final DuesSearchMode mode;
  final String query;

  const DuesSearch({this.mode = DuesSearchMode.household, this.query = ''});

  DuesSearch copyWith({DuesSearchMode? mode, String? query}) =>
      DuesSearch(mode: mode ?? this.mode, query: query ?? this.query);
}

/// Id of the signed-in user. Dues page state below watches it, so it resets when another user signs in.
final _duesUserIdProvider = Provider<String?>((ref) => ref.watch(currentAppUserProvider.select((u) => u.value?.id)));

final duesSearchProvider = StateProvider<DuesSearch>((ref) {
  ref.watch(_duesUserIdProvider);
  return const DuesSearch();
});

/// What the Collect tab has open: a household or a single member, by id.
typedef DuesSelection = ({DuesSearchMode mode, String id});

final duesSelectionProvider = StateProvider<DuesSelection?>((ref) {
  ref.watch(_duesUserIdProvider);
  return null;
});

final duesHouseholdResultsProvider = FutureProvider<List<DuesHousehold>>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  final search = ref.watch(duesSearchProvider);
  if (scope.isEmpty || search.mode != DuesSearchMode.household) return [];
  return ref.watch(supabaseServiceProvider).searchDuesHouseholds(scope: scope, query: search.query);
});

final duesMemberResultsProvider = FutureProvider<List<DuesMember>>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  final search = ref.watch(duesSearchProvider);
  if (scope.isEmpty || search.mode != DuesSearchMode.member) return [];
  return ref.watch(supabaseServiceProvider).searchDuesMembers(scope: scope, query: search.query);
});

/// The members a payment panel shows: a household's members, or the one member.
final duesPanelProvider = FutureProvider.family<DuesHousehold?, DuesSelection>((ref, sel) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  final service = ref.watch(supabaseServiceProvider);
  if (sel.mode == DuesSearchMode.household) return service.getDuesHousehold(sel.id, scope);
  final m = await service.getDuesMember(sel.id, scope);
  if (m == null) return null;
  return DuesHousehold(
    id: m.householdId,
    householdName: m.householdName ?? 'No household',
    lgu: m.lgu,
    barangay: m.barangay,
    purok: m.purok,
    members: [m],
  );
});

final duesLedgerQueryProvider = StateProvider<String>((ref) {
  ref.watch(_duesUserIdProvider);
  return '';
});
final duesLedgerPageProvider = StateProvider<int>((ref) {
  ref.watch(_duesUserIdProvider);
  return 0;
});

final duesReceiptsProvider = FutureProvider<List<DuesReceipt>>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  if (scope.isEmpty) return [];
  return ref.watch(supabaseServiceProvider).getDuesReceipts(
        scope: scope,
        query: ref.watch(duesLedgerQueryProvider),
        page: ref.watch(duesLedgerPageProvider),
      );
});

/// Total collected (non-void) for the ledger's current search, and this month's share.
final duesLedgerTotalsProvider = FutureProvider<({double total, double thisMonth, int receipts})>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  if (scope.isEmpty) return (total: 0.0, thisMonth: 0.0, receipts: 0);
  return ref.watch(supabaseServiceProvider).getDuesLedgerTotals(
        scope: scope,
        query: ref.watch(duesLedgerQueryProvider),
      );
});
