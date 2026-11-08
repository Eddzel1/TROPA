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

/// The ledger's search, period and location filters.
final duesLedgerFilterProvider = StateProvider<DuesLedgerFilter>((ref) {
  ref.watch(_duesUserIdProvider);
  return const DuesLedgerFilter();
});
final duesLedgerPageProvider = StateProvider<int>((ref) {
  ref.watch(_duesUserIdProvider);
  ref.watch(duesLedgerFilterProvider);
  return 0;
});

/// Receipts per ledger page.
const duesLedgerPageSize = 50;

final duesReceiptsProvider = FutureProvider<List<DuesReceipt>>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  if (scope.isEmpty) return [];
  return ref.watch(supabaseServiceProvider).getDuesReceipts(
        scope: scope,
        filter: ref.watch(duesLedgerFilterProvider),
        page: ref.watch(duesLedgerPageProvider),
        pageSize: duesLedgerPageSize,
      );
});

/// Totals for the ledger's current filters.
final duesLedgerTotalsProvider =
    FutureProvider<({double total, int receipts, int households, int voided, double voidedAmount})>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  if (scope.isEmpty) return (total: 0.0, receipts: 0, households: 0, voided: 0, voidedAmount: 0.0);
  return ref.watch(supabaseServiceProvider).getDuesLedgerTotals(scope: scope, filter: ref.watch(duesLedgerFilterProvider));
});

/// All receipts (void included) the ledger filters match, for the pager.
final duesLedgerCountProvider = FutureProvider<int>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  if (scope.isEmpty) return 0;
  return ref.watch(supabaseServiceProvider).countDuesReceipts(scope: scope, filter: ref.watch(duesLedgerFilterProvider));
});

/// The barangay and purok the Collect tab walks through. Null parts mean not chosen yet.
typedef DuesPurok = ({String? lgu, String? barangay, String? purok});

final duesPurokProvider = StateProvider<DuesPurok>((ref) {
  ref.watch(_duesUserIdProvider);
  return (lgu: null, barangay: null, purok: null);
});

/// Households of the chosen purok with their in-scope members, by name; empty until a purok is chosen.
final duesPurokHouseholdsProvider = FutureProvider<List<DuesHousehold>>((ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  final p = ref.watch(duesPurokProvider);
  if (scope.isEmpty || p.lgu == null || p.barangay == null || p.purok == null) return [];
  final list = await ref
      .watch(supabaseServiceProvider)
      .getDuesHouseholdsByPurok(scope: scope, lgu: p.lgu!, barangay: p.barangay!, purok: p.purok);
  return list..sort((a, b) => a.householdName.compareTo(b.householdName));
});

/// What was collected today (GMT+8) in the chosen purok, for the Collect tab's summary.
final duesPurokTodayProvider = FutureProvider<({double total, int receipts, int households, int voided, double voidedAmount})?>(
    (ref) async {
  ref.watch(tableChangesProvider(_duesTables));
  final scope = await ref.watch(duesScopeProvider.future);
  final p = ref.watch(duesPurokProvider);
  if (scope.isEmpty || p.purok == null) return null;
  return ref.watch(supabaseServiceProvider).getDuesLedgerTotals(
        scope: scope,
        filter: DuesLedgerFilter(period: LedgerPeriod.today, lgu: p.lgu, barangay: p.barangay, purok: p.purok),
      );
});

/// Dues starting month (`YYYY-MM`) per barangay that has one, keyed `LGU|BARANGAY` (upper-cased,
/// trimmed). New members encoded there adopt it.
final barangayStartMonthsProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(tableChangesProvider('locations'));
  return ref.watch(supabaseServiceProvider).getBarangayStartMonths();
});

/// The starting month for [lgu] / [barangay] from [months], or null.
String? startMonthFor(Map<String, String> months, String? lgu, String? barangay) =>
    months['${(lgu ?? '').trim().toUpperCase()}|${(barangay ?? '').trim().toUpperCase()}'];
