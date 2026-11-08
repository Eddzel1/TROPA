import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/motion.dart';
import '../core/dues_math.dart';
import '../core/geo.dart';
import '../core/ph_time.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/dues_provider.dart';
import '../providers/voter_provider.dart';
import '../widgets/form_fields.dart';
import '../widgets/keyboard_safe_body.dart';
import '../widgets/membership_date_dialog.dart';
import 'dues_sheet_print.dart';
import 'settings/settings_common.dart';

/// Below this page height (keyboard up, small phone) the page drops its description and badges.
const _shortHeight = 520.0;

/// Below this height a tab hides its extras (barangay link, ledger totals and pager).
const _shortTabHeight = 400.0;

final _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
final _dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');

/// Dues & Ledger: find a household or member in the collector's barangays, see what they owe,
/// record a payment, and review or void receipts.
class DuesCollectionView extends ConsumerWidget {
  const DuesCollectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final scopeAsync = ref.watch(duesScopeProvider);
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    final currentRate = rates.isEmpty ? null : rateForMonth(currentMonthIndex(), rates);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, constraints) {
        // Phones: the app bar already shows the title. With the keyboard up, the description and
        // badges give their room to the search box and results.
        final narrow = TropaBreakpoints.isCompact(constraints.maxWidth);
        final short = constraints.maxHeight < _shortHeight;
        final scope = scopeAsync.value;
        void openPrint() => showTropaDialog<void>(context: context, builder: (_) => _PrintSheetDialog(scope: scope!));
        final canPrint = scope != null && !scope.isEmpty;
        return KeyboardSafeBody(
        minHeight: 360,
        padding: EdgeInsets.all(narrow ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!narrow) ...[
              Row(
                children: [
                  Expanded(child: Text('Dues & Ledger', style: TropaText.pageTitle(textCol))),
                  if (canPrint)
                    OutlinedButton.icon(
                      onPressed: openPrint,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Print sheet'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (!short) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Monthly dues per member, counted from each membership date', style: TropaText.meta(subCol)),
                if (scopeAsync.value case final scope?)
                  TropaBadge(
                    scope.everywhere
                        ? 'All barangays'
                        : scope.barangays.isEmpty
                            ? 'No barangays assigned'
                            : scope.barangays.map((b) => b.barangay).join(', '),
                    icon: Icons.location_on_outlined,
                    color: scope.isEmpty ? TropaColors.errorOf(context) : null,
                  ),
                TropaBadge(
                  currentRate == null ? 'No dues rate set' : '${_peso.format(currentRate)} / member / month',
                  icon: Icons.payments_outlined,
                  color: currentRate == null ? TropaColors.errorOf(context) : TropaColors.secondaryStrongOf(context),
                ),
                // Phones have no title row, so the print button sits with the badges.
                if (narrow && canPrint)
                  IconButton(
                    tooltip: 'Print sheet',
                    visualDensity: VisualDensity.compact,
                    onPressed: openPrint,
                    icon: const Icon(Icons.print_outlined, size: 20),
                  ),
              ],
            ),
            SizedBox(height: narrow ? 12 : 16),
            ],
            Expanded(
              child: scopeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Could not load your barangays: $e', style: TropaText.body(textCol))),
                data: (scope) => scope.isEmpty
                    ? const _EmptyState(
                        icon: Icons.location_off_outlined,
                        title: 'No barangays assigned',
                        message: 'Ask an administrator to assign the barangays you collect dues for '
                            '(Settings › Users & Permissions).',
                      )
                    : const _DuesTabs(),
              ),
            ),
          ],
        ),
        );
      }),
    );
  }
}

class _DuesTabs extends StatelessWidget {
  const _DuesTabs();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Text-only tabs (~46 px instead of 72) when the keyboard leaves little room.
      final short = constraints.maxHeight < _shortTabHeight + 80;
      return DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: short
                  ? const [Tab(text: 'Collect'), Tab(text: 'Ledger')]
                  : const [
                      Tab(icon: Icon(Icons.add_card, size: 18), text: 'Collect'),
                      Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Ledger'),
                    ],
            ),
            SizedBox(height: short ? 8 : 16),
            const Expanded(child: TabBarView(children: [_CollectTab(), _LedgerTab()])),
          ],
        ),
      );
    });
  }
}

// ==========================================
// Collect
// ==========================================
class _CollectTab extends ConsumerStatefulWidget {
  const _CollectTab();

  @override
  ConsumerState<_CollectTab> createState() => _CollectTabState();
}

class _CollectTabState extends ConsumerState<_CollectTab> {
  late final _searchCtrl = TextEditingController(text: ref.read(duesSearchProvider).query);
  Timer? _debounce;

  /// Hides up-to-date households from the purok checklist.
  bool _unpaidOnly = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(TropaMotion.searchDebounce, () {
      if (!mounted) return;
      ref.read(duesSearchProvider.notifier).update((s) => s.copyWith(query: value.trim()));
    });
  }

  void _open(DuesSelection sel, {required bool wide}) {
    ref.read(duesSelectionProvider.notifier).state = sel;
    if (wide) return;
    showTropaDialog(
      context: context,
      builder: (c) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Padding(padding: const EdgeInsets.all(16), child: _PaymentPanel(selection: sel)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(duesSearchProvider);
    final selection = ref.watch(duesSelectionProvider);
    final purok = ref.watch(duesPurokProvider);
    // A chosen purok turns the household list into a walk-through checklist.
    final walking = search.mode == DuesSearchMode.household && purok.purok != null;

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 860;
      final short = constraints.maxHeight < _shortTabHeight;
      final list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<DuesSearchMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: DuesSearchMode.household, icon: Icon(Icons.home_outlined, size: 18), label: Text('Household')),
              ButtonSegment(
                  value: DuesSearchMode.member, icon: Icon(Icons.person_outline, size: 18), label: Text('Member')),
            ],
            selected: {search.mode},
            onSelectionChanged: (s) => ref.read(duesSearchProvider.notifier).update((v) => v.copyWith(mode: s.first)),
          ),
          if (search.mode == DuesSearchMode.household) ...[
            SizedBox(height: short ? 8 : 12),
            _LocationPickers(
              lgu: purok.lgu,
              barangay: purok.barangay,
              purok: purok.purok,
              onChanged: (lgu, barangay, p) {
                ref.read(duesPurokProvider.notifier).state = (lgu: lgu, barangay: barangay, purok: p);
                // The open household belongs to the old place; show the new purok's summary instead.
                ref.read(duesSelectionProvider.notifier).state = null;
              },
            ),
          ],
          SizedBox(height: short ? 8 : 12),
          TextField(
            inputFormatters: const [UpperCaseFormatter()],
            textCapitalization: TextCapitalization.characters,
            controller: _searchCtrl,
            style: TropaStyles.fieldText(context),
            decoration: TropaStyles.filterField(
              context,
              hint: walking
                  ? 'Find in this purok…'
                  : search.mode == DuesSearchMode.household
                      ? 'Household or member name…'
                      : 'Member name…',
              search: true,
            ),
            onChanged: _search,
          ),
          if (walking && !short) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(child: _PurokProgress()),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('Unpaid only'),
                  selected: _unpaidOnly,
                  onSelected: (v) => setState(() => _unpaidOnly = v),
                ),
              ],
            ),
          ],
          SizedBox(height: short ? 8 : 12),
          Expanded(
            child: switch (search.mode) {
              _ when walking => _PurokChecklist(
                  query: search.query,
                  unpaidOnly: _unpaidOnly,
                  selectedId: selection?.id,
                  onOpen: (id) => _open((mode: DuesSearchMode.household, id: id), wide: wide)),
              DuesSearchMode.household => _HouseholdResults(
                  selectedId: selection?.id,
                  onOpen: (id) => _open((mode: DuesSearchMode.household, id: id), wide: wide)),
              DuesSearchMode.member => _MemberResults(
                  selectedId: selection?.id,
                  onOpen: (id) => _open((mode: DuesSearchMode.member, id: id), wide: wide)),
            },
          ),
        ],
      );

      if (!wide) return list;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 400, child: list),
          const SizedBox(width: 20),
          Expanded(
            child: _Surface(
              padding: const EdgeInsets.all(20),
              child: switch (selection) {
                final sel? => _PaymentPanel(key: ValueKey(sel), selection: sel),
                null when walking => const _PurokSummary(),
                null => const _EmptyState(
                    icon: Icons.touch_app_outlined,
                    title: 'Choose a household or member',
                    message: 'Their unpaid months and amount due appear here.',
                  ),
              },
            ),
          ),
        ],
      );
    });
  }
}

/// Sum of what [members] owe now.
({int months, double amount, int unbilled}) _totals(List<DuesMember> members, List<DuesRate> rates) {
  var months = 0;
  var amount = 0.0;
  var unbilled = 0;
  for (final m in members) {
    final b = balanceFor(m, rates);
    if (b == null) {
      if (m.isCoopMember) unbilled++;
      continue;
    }
    if (b.monthsOwed > 0) months += b.monthsOwed;
    amount += b.amountDue;
  }
  return (months: months, amount: amount, unbilled: unbilled);
}

class _HouseholdResults extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String> onOpen;

  const _HouseholdResults({required this.selectedId, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    return ref.watch(duesHouseholdResultsProvider).when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Search failed: $e')),
          data: (households) {
            if (households.isEmpty) {
              return const _EmptyState(
                  icon: Icons.search_off, title: 'No households found', message: 'Try another name.');
            }
            return _Surface(
              child: ListView.separated(
                itemCount: households.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(context)),
                itemBuilder: (context, i) {
                  final h = households[i];
                  final t = _totals(h.members, rates);
                  return ListTile(
                    selected: h.id == selectedId,
                    leading: const Icon(Icons.home_outlined),
                    title: Text(h.householdName, style: TropaText.bodyStrong(TropaColors.textHigh(context))),
                    subtitle: Text(
                      '${h.barangay}${h.purok.isEmpty ? '' : ' · ${h.purok}'} · ${h.members.length} member${h.members.length == 1 ? '' : 's'}'
                      '${h.membersElsewhere > 0 ? ' (+${h.membersElsewhere} elsewhere)' : ''}'
                      '${t.unbilled > 0 ? ' · ${t.unbilled} need a date' : ''}',
                      style: TropaText.caption(TropaColors.textMedium(context)),
                    ),
                    trailing: _OwedLabel(months: t.months, amount: t.amount),
                    onTap: () => onOpen(h.id),
                  );
                },
              ),
            );
          },
        );
  }
}

class _MemberResults extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String> onOpen;

  const _MemberResults({required this.selectedId, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    return ref.watch(duesMemberResultsProvider).when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Search failed: $e')),
          data: (members) {
            if (members.isEmpty) {
              return const _EmptyState(icon: Icons.search_off, title: 'No members found', message: 'Try another name.');
            }
            return _Surface(
              child: ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(context)),
                itemBuilder: (context, i) {
                  final m = members[i];
                  final b = balanceFor(m, rates);
                  return ListTile(
                    selected: m.id == selectedId,
                    leading: const Icon(Icons.person_outline),
                    title: Text(m.fullName, style: TropaText.bodyStrong(TropaColors.textHigh(context))),
                    subtitle: Text(
                      '${m.barangay}${m.householdName == null ? '' : ' · ${m.householdName}'}',
                      style: TropaText.caption(TropaColors.textMedium(context)),
                    ),
                    trailing: b == null
                        ? Text(unbilledReason(m), style: TropaText.caption(TropaColors.textMedium(context)))
                        : _OwedLabel(months: b.monthsOwed, amount: b.amountDue),
                    onTap: () => onOpen(m.id),
                  );
                },
              ),
            );
          },
        );
  }
}

/// Cascading LGU › Barangay › Purok dropdowns over the user's dues barangays. An LGU or barangay
/// that is the only choice is picked for the user. With [anyLabels] an empty choice reads "All …"
/// (ledger filters); otherwise "Choose …" (Collect).
class _LocationPickers extends ConsumerWidget {
  final String? lgu;
  final String? barangay;
  final String? purok;
  final bool anyLabels;
  final void Function(String? lgu, String? barangay, String? purok) onChanged;

  const _LocationPickers({
    required this.lgu,
    required this.barangay,
    required this.purok,
    required this.onChanged,
    this.anyLabels = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(duesScopeProvider).value;
    final locations = scope == null
        ? const <LocationOption>[]
        : scope.everywhere
            ? ref.watch(locationsProvider).value ?? const <LocationOption>[]
            : scope.barangays;
    final lgus = {for (final l in locations) l.lgu}.toList()..sort();
    final effLgu = lgu ?? (lgus.length == 1 ? lgus.first : null);
    final barangays = [for (final l in locations) if (l.lgu == effLgu) l]..sort((a, b) => a.barangay.compareTo(b.barangay));
    final effBarangay = barangay ?? (barangays.length == 1 ? barangays.first.barangay : null);
    final location = barangays.where((l) => l.barangay == effBarangay).firstOrNull;
    final puroks = location == null
        ? const <String>[]
        : [for (final p in ref.watch(puroksProvider(location.id)).value ?? const <({String id, String name})>[]) p.name];

    Widget dropdown(String empty, String? value, List<String> items, ValueChanged<String?>? changed) {
      final current = items.contains(value) ? value : null;
      return DropdownButtonFormField<String?>(
        icon: TropaStyles.dropdownIcon(context),
        // Rebuilt when the choice or its options change, since the field keeps its own value.
        key: ValueKey('$empty|$current|${items.length}'),
        initialValue: current,
        isExpanded: true,
        style: TropaStyles.fieldText(context),
        decoration: TropaStyles.filterField(context),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(empty, overflow: TextOverflow.ellipsis)),
          for (final i in items) DropdownMenuItem<String?>(value: i, child: Text(i, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: changed,
      );
    }

    final lguField =
        dropdown(anyLabels ? 'All LGUs' : 'Choose LGU', effLgu, lgus, (v) => onChanged(v, null, null));
    final barangayField = dropdown(
      anyLabels ? 'All barangays' : 'Choose barangay',
      effBarangay,
      [for (final b in barangays) b.barangay],
      effLgu == null ? null : (v) => onChanged(effLgu, v, null),
    );
    final purokField = dropdown(
      anyLabels ? 'All puroks' : 'Choose purok',
      purok,
      puroks,
      location == null ? null : (v) => onChanged(effLgu, effBarangay, v),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 520) {
        return Row(children: [
          Expanded(child: lguField),
          const SizedBox(width: 8),
          Expanded(child: barangayField),
          const SizedBox(width: 8),
          Expanded(child: purokField),
        ]);
      }
      return Column(children: [
        Row(children: [Expanded(child: lguField), const SizedBox(width: 8), Expanded(child: barangayField)]),
        const SizedBox(height: 8),
        purokField,
      ]);
    });
  }
}

bool _upToDate(DuesHousehold h, List<DuesRate> rates) => _totals(h.members, rates).months <= 0;

/// The chosen purok's households as a checklist in walking (name) order: ✓ when nobody owes,
/// otherwise what is owed. [query] narrows by household or member name.
class _PurokChecklist extends ConsumerWidget {
  final String query;
  final bool unpaidOnly;
  final String? selectedId;
  final ValueChanged<String> onOpen;

  const _PurokChecklist({required this.query, required this.unpaidOnly, required this.selectedId, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final words = query.toUpperCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    bool matches(DuesHousehold h) => words.every((w) =>
        h.householdName.toUpperCase().contains(w) || h.members.any((m) => m.fullName.toUpperCase().contains(w)));

    return ref.watch(duesPurokHouseholdsProvider).when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load the purok: $e')),
          data: (all) {
            final households =
                all.where((h) => matches(h) && (!unpaidOnly || !_upToDate(h, rates))).toList();
            if (households.isEmpty) {
              return _EmptyState(
                icon: all.isEmpty ? Icons.home_outlined : Icons.task_alt,
                title: all.isEmpty ? 'No households here' : (unpaidOnly ? 'Everyone here is up to date' : 'No match'),
                message: all.isEmpty ? 'No households with members to bill in this purok.' : 'Try another name.',
              );
            }
            return _Surface(
              child: ListView.separated(
                itemCount: households.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(context)),
                itemBuilder: (context, i) {
                  final h = households[i];
                  final t = _totals(h.members, rates);
                  final done = t.months <= 0;
                  return ListTile(
                    selected: h.id == selectedId,
                    leading: Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? TropaColors.secondaryStrongOf(context) : TropaColors.textDisabled(context),
                    ),
                    title: Text(h.householdName, style: TropaText.bodyStrong(textCol)),
                    subtitle: Text(
                      '${h.members.length} member${h.members.length == 1 ? '' : 's'}'
                      '${t.unbilled > 0 ? ' · ${t.unbilled} need a date' : ''}',
                      style: TropaText.caption(subCol),
                    ),
                    trailing: _OwedLabel(months: t.months, amount: t.amount),
                    onTap: () => onOpen(h.id),
                  );
                },
              ),
            );
          },
        );
  }
}

/// "12 of 30 up to date" with a thin progress bar, for the chosen purok.
class _PurokProgress extends ConsumerWidget {
  const _PurokProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    final households = ref.watch(duesPurokHouseholdsProvider).value;
    if (households == null || households.isEmpty) return const SizedBox.shrink();
    final done = households.where((h) => _upToDate(h, rates)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$done of ${households.length} households up to date',
            style: TropaText.meta(TropaColors.textMedium(context))),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: done / households.length,
            minHeight: 6,
            color: TropaColors.secondaryStrongOf(context),
            backgroundColor: TropaColors.chipOf(context),
          ),
        ),
      ],
    );
  }
}

/// Shown beside the checklist until a household is picked: what the purok still owes, how many
/// households are up to date, and what was collected there today.
class _PurokSummary extends ConsumerWidget {
  const _PurokSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    final purok = ref.watch(duesPurokProvider);
    final households = ref.watch(duesPurokHouseholdsProvider).value ?? const <DuesHousehold>[];
    final today = ref.watch(duesPurokTodayProvider).value;
    var owed = 0.0;
    var unpaid = 0;
    for (final h in households) {
      final t = _totals(h.members, rates);
      if (t.months > 0) {
        owed += t.amount;
        unpaid++;
      }
    }
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${purok.purok}, ${purok.barangay}', style: TropaText.dialogTitle(textCol)),
            Text('Pick a household on the left to record a payment.', style: TropaText.meta(subCol)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatTile(
                  label: 'Unpaid',
                  value: _peso.format(owed),
                  caption: '$unpaid household${unpaid == 1 ? '' : 's'}',
                  color: unpaid == 0 ? null : TropaColors.errorOf(context),
                ),
                _StatTile(
                  label: 'Up to date',
                  value: '${households.length - unpaid} of ${households.length}',
                  color: TropaColors.secondaryStrongOf(context),
                ),
                _StatTile(
                  label: 'Collected today',
                  value: _peso.format(today?.total ?? 0),
                  caption: '${today?.receipts ?? 0} receipt${today?.receipts == 1 ? '' : 's'}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwedLabel extends StatelessWidget {
  final int months;
  final double amount;

  const _OwedLabel({required this.months, required this.amount});

  @override
  Widget build(BuildContext context) {
    if (months <= 0) {
      return TropaBadge('Up to date', color: TropaColors.secondaryStrongOf(context), icon: Icons.check_circle_outline);
    }
    // Calm by default; amber from 6 months behind, red from 12.
    final color = months >= 12
        ? TropaColors.errorOf(context)
        : months >= 6
            ? TropaColors.offline
            : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(_peso.format(amount), style: TropaText.bodyStrong(color ?? TropaColors.textHigh(context))),
        Text('$months mo unpaid', style: TropaText.caption(color ?? TropaColors.textMedium(context))),
      ],
    );
  }
}

/// Members of the selected household (or the one member) with months to pay and the payment form.
class _PaymentPanel extends ConsumerStatefulWidget {
  final DuesSelection selection;

  const _PaymentPanel({super.key, required this.selection});

  @override
  ConsumerState<_PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<_PaymentPanel> {
  static const _methods = ['Cash', 'GCash', 'Maya', 'Bank Transfer'];

  final _months = <String, int>{};
  String? _defaultsFor;
  String _method = 'Cash';
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Resets months to "everything owed" whenever the members or their balances change.
  void _syncDefaults(DuesHousehold data, List<DuesRate> rates) {
    final key = [
      for (final m in data.members) '${m.id}:${m.monthsPaid}:${m.membershipDate}:${m.isCoopMember}',
      rates.length,
    ].join('|');
    if (key == _defaultsFor) return;
    _defaultsFor = key;
    _months.clear();
    for (final m in data.members) {
      final b = balanceFor(m, rates);
      if (b != null && b.monthsOwed > 0) _months[m.id] = b.monthsOwed;
    }
  }

  Future<void> _editDate(List<DuesMember> members, List<DuesRate> rates) async {
    final date = await showMembershipDateDialog(context, members: members, rates: rates);
    if (date == null || !mounted) return;
    try {
      await ref.read(supabaseServiceProvider).setMembershipDate([for (final m in members) m.id], date);
      if (mounted) showSettingsMessage(context, 'Membership month updated.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  /// Asks before saving: who pays for which months, the total, the method and the reference.
  Future<bool> _confirmPayment(DuesHousehold data, List<DuesRate> rates) async {
    final lines = <({String name, String months, double amount})>[];
    var total = 0.0;
    for (final m in data.members) {
      final n = _months[m.id] ?? 0;
      final b = balanceFor(m, rates);
      if (b == null || n <= 0) continue;
      final amount = b.amountFor(n);
      total += amount;
      lines.add((name: m.fullName, months: '$n mo · ${monthRangeLabel(b.nextUnpaidMonth, n)}', amount: amount));
    }
    final reference = _reference.text.trim();
    final ok = await showTropaDialog<bool>(
      context: context,
      builder: (c) {
        final textCol = TropaColors.textHigh(c);
        final subCol = TropaColors.textMedium(c);
        return AlertDialog(
          title: Text('Record ${_peso.format(total)}?'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.selection.mode == DuesSearchMode.household)
                    Text(data.householdName, style: TropaText.sectionTitle(textCol)),
                  const SizedBox(height: 8),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.name, style: TropaText.bodyStrong(textCol)),
                                Text(l.months, style: TropaText.caption(subCol)),
                              ],
                            ),
                          ),
                          Text(_peso.format(l.amount), style: TropaText.body(textCol)),
                        ],
                      ),
                    ),
                  Divider(height: 20, color: TropaColors.borderOf(c)),
                  Row(
                    children: [
                      Expanded(child: Text('Total', style: TropaText.sectionTitle(textCol))),
                      Text(_peso.format(total), style: TropaText.sectionTitle(TropaColors.secondaryStrongOf(c))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_method · ${reference.isEmpty ? 'no receipt / reference #' : 'Ref $reference'}',
                    style: TropaText.meta(subCol),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Go back')),
            FilledButton.icon(
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Record payment'),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  Future<void> _record(DuesHousehold data, List<DuesRate> rates) async {
    if (!await _confirmPayment(data, rates) || !mounted) return;
    setState(() => _saving = true);
    final user = ref.read(currentAppUserProvider).value;
    try {
      final receipt = await ref.read(supabaseServiceProvider).recordDuesPayment(
            scope: await ref.read(duesScopeProvider.future),
            months: Map.of(_months),
            rates: rates,
            paymentMethod: _method,
            collectedBy: user?.fullName ?? 'Staff',
            referenceNumber: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (!mounted) return;
      _reference.clear();
      _notes.clear();
      setState(() => _saving = false);
      await showTropaDialog(context: context, builder: (_) => _ReceiptDialog(receipt: receipt));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];

    return ref.watch(duesPanelProvider(widget.selection)).when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load: $e')),
          data: (data) {
            if (data == null) {
              return const _EmptyState(
                  icon: Icons.help_outline, title: 'Not found', message: 'This record may have been removed.');
            }
            _syncDefaults(data, rates);
            final isHousehold = widget.selection.mode == DuesSearchMode.household;
            final title = isHousehold ? data.householdName : data.members.first.fullName;
            var totalMonths = 0;
            var total = 0.0;
            for (final m in data.members) {
              final n = _months[m.id] ?? 0;
              final b = balanceFor(m, rates);
              if (b == null || n <= 0) continue;
              totalMonths += n;
              total += b.amountFor(n);
            }
            final canRecord = !_saving && totalMonths > 0 && rates.isNotEmpty;

            // On a phone the keyboard (receipt #, notes) would squeeze this below its fixed parts;
            // then the panel scrolls so the focused field and Record button stay reachable.
            return KeyboardSafeBody(
              minHeight: 620,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TropaText.dialogTitle(textCol)),
                          Text(
                            [data.barangay, if (data.purok.isNotEmpty) data.purok, if (!isHousehold) data.householdName]
                                .join(' · '),
                            style: TropaText.meta(subCol),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (data.membersElsewhere > 0) ...[
                  const SizedBox(height: 12),
                  _Notice(
                    '${data.membersElsewhere} member${data.membersElsewhere == 1 ? ' is' : 's are'} registered in another '
                    'barangay and not shown. Their dues are collected there.',
                    color: subCol,
                  ),
                ],
                if (rates.isEmpty) ...[
                  const SizedBox(height: 12),
                  _Notice(
                    'No dues rate is set yet, so nothing can be billed. An administrator sets it in Settings › Dues Rate.',
                    color: TropaColors.errorOf(context),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('MEMBERS', style: TropaText.groupLabel(subCol)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _defaultsFor = null;
                        _syncDefaults(data, rates);
                      }),
                      child: const Text('All unpaid'),
                    ),
                    TextButton(onPressed: () => setState(_months.clear), child: const Text('Clear')),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: data.members.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(context)),
                    itemBuilder: (context, i) {
                      final m = data.members[i];
                      return _MemberPayRow(
                        member: m,
                        balance: balanceFor(m, rates),
                        months: _months[m.id] ?? 0,
                        onMonths: (n) => setState(() => n <= 0 ? _months.remove(m.id) : _months[m.id] = n),
                        onEditDate: () => _editDate([m], rates),
                      );
                    },
                  ),
                ),
                Divider(height: 24, color: TropaColors.borderOf(context)),
                Row(
                  children: [
                    Text('Total · $totalMonths month${totalMonths == 1 ? '' : 's'}',
                        style: TropaText.sectionTitle(textCol)),
                    const Spacer(),
                    Text(
                      _peso.format(total),
                      style: TropaText.kpi(TropaColors.secondaryStrongOf(context), size: 22)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Payment method',
                        child: DropdownButtonFormField<String>(
                          icon: TropaStyles.dropdownIcon(context),
                          initialValue: _method,
                          style: TropaStyles.fieldText(context),
                          decoration: TropaStyles.formField(context),
                          items: [for (final m in _methods) DropdownMenuItem(value: m, child: Text(m))],
                          onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: 'Receipt / reference #',
                        child: TextField(
                          inputFormatters: const [UpperCaseFormatter()],
                          textCapitalization: TextCapitalization.characters,
                          controller: _reference,
                          style: TropaStyles.fieldText(context),
                          decoration: TropaStyles.formField(context, hint: 'OR number or transaction ID'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Notes',
                  child: TextField(
                    inputFormatters: const [UpperCaseFormatter()],
                    textCapitalization: TextCapitalization.characters,
                    controller: _notes,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.formField(context),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: TropaStyles.primaryAction(context),
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check, size: 18),
                    label: Text('Record ${_peso.format(total)}'),
                    onPressed: canRecord ? () => _record(data, rates) : null,
                  ),
                ),
              ],
              ),
            );
          },
        );
  }
}

class _MemberPayRow extends StatelessWidget {

  final DuesMember member;
  final DuesBalance? balance;
  final int months;
  final ValueChanged<int> onMonths;
  final VoidCallback onEditDate;

  const _MemberPayRow({
    required this.member,
    required this.balance,
    required this.months,
    required this.onMonths,
    required this.onEditDate,
  });

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final b = balance;
    final date = member.membershipDate;
    // Phones: tighter stepper and amount column so the name column keeps its room.
    final compact = context.isCompactScreen;
    const tight = VisualDensity(horizontal: -4, vertical: -2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: TropaText.bodyStrong(textCol)),
                InkWell(
                  onTap: onEditDate,
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          date == null ? 'Set membership month' : 'Member since ${membershipMonthLabel(date)}',
                          style: TropaText.caption(date == null ? TropaColors.errorOf(context) : subCol),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 13, color: subCol),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  b == null
                      ? unbilledReason(member)
                      : months > 0
                          ? '${b.statusLabel} · paying ${monthRangeLabel(b.nextUnpaidMonth, months)}'
                          : b.statusLabel,
                  style: TropaText.caption(b != null && b.monthsOwed > 0 ? TropaColors.errorOf(context) : subCol),
                ),
              ],
            ),
          ),
          if (b != null) ...[
            IconButton(
              tooltip: 'One month less',
              visualDensity: compact ? tight : null,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: months > 0 ? () => onMonths(months - 1) : null,
            ),
            SizedBox(
              width: compact ? 24 : 28,
              child: Text('$months', textAlign: TextAlign.center, style: TropaText.bodyStrong(textCol)),
            ),
            IconButton(
              tooltip: months < b.maxPayableMonths
                  ? 'One month more (pays ahead once the balance is cleared)'
                  : 'At most $maxMonthsAhead months ahead',
              visualDensity: compact ? tight : null,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: months < b.maxPayableMonths ? () => onMonths(months + 1) : null,
            ),
            SizedBox(
              width: compact ? 72 : 96,
              child: Text(
                _peso.format(b.amountFor(months)),
                textAlign: TextAlign.right,
                style: TropaText.body(textCol).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  final DuesReceipt receipt;
  final String title;

  const _ReceiptDialog({required this.receipt, this.title = 'Payment recorded'});

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    Widget line(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 110, child: Text(k, style: TropaText.meta(subCol))),
              Expanded(child: Text(v, style: TropaText.body(textCol))),
            ],
          ),
        );

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _peso.format(receipt.total),
                  style: TropaText.kpi(receipt.isVoid ? subCol : TropaColors.secondaryStrongOf(context))
                      .copyWith(decoration: receipt.isVoid ? TextDecoration.lineThrough : null),
                ),
                if (receipt.isVoid) ...[
                  const SizedBox(width: 10),
                  TropaBadge('VOID', color: TropaColors.errorOf(context)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (receipt.householdName != null) line('Household', receipt.householdName!),
            line('Members', receipt.memberNames),
            line('Months', receiptMonthsLabel(receipt)),
            line('Method', receipt.paymentMethod),
            if (receipt.referenceNumber != null) line('Reference', receipt.referenceNumber!),
            line('Date', formatPh(_dateTimeFormat, receipt.paymentDate)),
            line('Collected by', receipt.collectedBy),
            if (receipt.isVoid && receipt.voidReason != null) line('Void reason', receipt.voidReason!),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
    );
  }
}

/// Picks a barangay, purok and year, then prints that purok's collection sheet.
class _PrintSheetDialog extends ConsumerStatefulWidget {
  final DuesScope scope;

  const _PrintSheetDialog({required this.scope});

  @override
  ConsumerState<_PrintSheetDialog> createState() => _PrintSheetDialogState();
}

class _PrintSheetDialogState extends ConsumerState<_PrintSheetDialog> {
  String? _lgu;
  String? _locationId;

  /// Null prints every purok.
  String? _purok;
  int _year = phToday().year;
  bool _printing = false;

  Future<void> _print(LocationOption location) async {
    setState(() => _printing = true);
    try {
      final households = await ref.read(supabaseServiceProvider).getDuesHouseholdsByPurok(
            scope: widget.scope,
            lgu: location.lgu,
            barangay: location.barangay,
            purok: _purok,
          );
      if (households.isEmpty) throw Exception('No households with members to bill here.');
      final purok = _purok;
      final year = _year;
      final rates = ref.read(duesRatesProvider).value ?? const <DuesRate>[];
      if (!mounted) return;
      // Closing the preview comes back here, to pick another purok or year.
      await Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DuesSheetPreview(
          title: 'Dues Sheet · ${location.barangay} · ${purok ?? 'All puroks'} · $year',
          build: (format) => buildDuesSheet(
            households: households,
            barangayLabel: '${location.barangay}, ${location.lgu}',
            purok: purok,
            year: year,
            rates: rates,
            format: format,
          ),
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not print the sheet: $e')));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = widget.scope.everywhere
        ? ref.watch(locationsProvider).value ?? const <LocationOption>[]
        : widget.scope.barangays;
    final lgus = {for (final l in locations) l.lgu}.toList()..sort();
    if (_lgu == null && lgus.length == 1) _lgu = lgus.first;
    final barangays = [for (final l in locations) if (l.lgu == _lgu) l]..sort((a, b) => a.barangay.compareTo(b.barangay));
    if (_locationId == null && barangays.length == 1) _locationId = barangays.first.id;
    final location = barangays.where((l) => l.id == _locationId).firstOrNull;
    final puroks = location == null
        ? const <String>[]
        : [for (final p in ref.watch(puroksProvider(location.id)).value ?? const <({String id, String name})>[]) p.name];
    final thisYear = phToday().year;

    return AlertDialog(
      title: const Text('Print collection sheet'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Households and members of one purok, with a box for each month. Paid months are '
                'marked; months crossed with an X are not billed.',
                style: TropaText.meta(TropaColors.textMedium(context))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              icon: TropaStyles.dropdownIcon(context),
              // Rebuilt once the location list loads, to show a preselected sole LGU.
              key: ValueKey(lgus.length),
              initialValue: _lgu,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'LGU'),
              items: [
                for (final l in lgus) DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() {
                _lgu = v;
                _locationId = null;
                _purok = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              icon: TropaStyles.dropdownIcon(context),
              // Rebuilt per LGU, so the barangay choice resets with it.
              key: ValueKey('$_lgu|${barangays.length}'),
              initialValue: location?.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Barangay'),
              items: [
                for (final l in barangays)
                  DropdownMenuItem(value: l.id, child: Text(l.barangay, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: _lgu == null
                  ? null
                  : (v) => setState(() {
                        _locationId = v;
                        _purok = null;
                      }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              icon: TropaStyles.dropdownIcon(context),
              // Rebuilt per barangay, so the purok choice resets with it.
              key: ValueKey(location?.id),
              initialValue: puroks.contains(_purok) ? _purok : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Purok'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All puroks')),
                for (final p in puroks) DropdownMenuItem<String?>(value: p, child: Text(p)),
              ],
              onChanged: location == null ? null : (v) => setState(() => _purok = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              icon: TropaStyles.dropdownIcon(context),
              initialValue: _year,
              decoration: const InputDecoration(labelText: 'Year'),
              items: [
                for (var y = thisYear - 2; y <= thisYear + 1; y++) DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) => setState(() => _year = v ?? _year),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _printing || location == null ? null : () => _print(location),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(_printing ? 'Preparing…' : 'Preview'),
        ),
      ],
    );
  }
}

// ==========================================
// Ledger
// ==========================================
class _LedgerTab extends ConsumerStatefulWidget {
  const _LedgerTab();

  @override
  ConsumerState<_LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends ConsumerState<_LedgerTab> {
  late final _searchCtrl = TextEditingController(text: ref.read(duesLedgerFilterProvider).query);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _update(DuesLedgerFilter Function(DuesLedgerFilter f) change) =>
      ref.read(duesLedgerFilterProvider.notifier).update(change);

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(TropaMotion.searchDebounce, () {
      if (mounted) _update((f) => f.copyWith(query: value.trim()));
    });
  }

  Future<void> _pickRange(DuesLedgerFilter filter) async {
    final today = phToday();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: filter.from != null && filter.to != null ? DateTimeRange(start: filter.from!, end: filter.to!) : null,
    );
    if (picked == null) return;
    _update((f) => f.copyWith(period: LedgerPeriod.custom, from: picked.start, to: picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(duesLedgerFilterProvider);
    final page = ref.watch(duesLedgerPageProvider);
    final receiptsAsync = ref.watch(duesReceiptsProvider);
    final totals = ref.watch(duesLedgerTotalsProvider).value;
    final count = ref.watch(duesLedgerCountProvider).value ?? 0;
    final subCol = TropaColors.textMedium(context);

    final search = TextField(
      inputFormatters: const [UpperCaseFormatter()],
      textCapitalization: TextCapitalization.characters,
      controller: _searchCtrl,
      style: TropaStyles.fieldText(context),
      decoration: TropaStyles.filterField(context, hint: 'Name, household, reference or month (YYYY-MM)…', search: true),
      onChanged: _search,
    );
    final pickers = _LocationPickers(
      lgu: filter.lgu,
      barangay: filter.barangay,
      purok: filter.purok,
      anyLabels: true,
      onChanged: (lgu, barangay, purok) =>
          _update((f) => f.copyWith(lgu: () => lgu, barangay: () => barangay, purok: () => purok)),
    );

    final customLabel = filter.period == LedgerPeriod.custom && filter.from != null && filter.to != null
        ? '${_dayFormat.format(filter.from!)} – ${_dayFormat.format(filter.to!)}'
        : 'Custom…';
    final periods = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (p, label) in [
          (LedgerPeriod.all, 'All time'),
          (LedgerPeriod.today, 'Today'),
          (LedgerPeriod.week, 'This week'),
          (LedgerPeriod.month, 'This month'),
        ])
          ChoiceChip(
            label: Text(label),
            selected: filter.period == p,
            onSelected: (_) => _update((f) => f.copyWith(period: p)),
          ),
        ChoiceChip(
          avatar: const Icon(Icons.date_range, size: 16),
          label: Text(customLabel),
          selected: filter.period == LedgerPeriod.custom,
          onSelected: (_) => _pickRange(filter),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      // With the keyboard up, the totals and pager give their room to the search box and receipts.
      final short = constraints.maxHeight < _shortTabHeight;
      final wide = constraints.maxWidth >= _ledgerTableWidth;
      final pages = (count / duesLedgerPageSize).ceil();
      final first = page * duesLedgerPageSize + 1;
      final last = first - 1 + (receiptsAsync.value?.length ?? 0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(flex: 2, child: search), const SizedBox(width: 10), Expanded(flex: 3, child: pickers)],
            )
          else ...[
            search,
            const SizedBox(height: 8),
            pickers,
          ],
          if (!short) ...[
            const SizedBox(height: 10),
            periods,
            if (totals != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatTile(
                    label: 'Collected',
                    value: _peso.format(totals.total),
                    color: TropaColors.secondaryStrongOf(context),
                  ),
                  _StatTile(label: 'Receipts', value: '${totals.receipts}'),
                  _StatTile(label: 'Households paid', value: '${totals.households}'),
                  _StatTile(
                    label: 'Voided',
                    value: '${totals.voided}',
                    caption: totals.voided == 0 ? null : _peso.format(totals.voidedAmount),
                    color: totals.voided == 0 ? null : TropaColors.errorOf(context),
                  ),
                ],
              ),
            ],
          ],
          SizedBox(height: short ? 8 : 12),
          Expanded(
            child: receiptsAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading ledger: $e')),
              data: (receipts) => receipts.isEmpty
                  ? _EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No receipts',
                      message: filter.isFiltered
                          ? 'Nothing matches these filters.'
                          : 'Payments recorded on the Collect tab appear here.',
                    )
                  : _Surface(
                      child: Column(
                        children: [
                          if (wide) const _LedgerHeader(),
                          Expanded(
                            child: ListView.separated(
                              itemCount: receipts.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(context)),
                              itemBuilder: (_, i) => _ReceiptRow(receipt: receipts[i], wide: wide),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (!short && count > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Showing $first–$last of $count', style: TropaText.meta(subCol))),
                IconButton(
                  tooltip: 'Newer',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: page > 0 ? () => ref.read(duesLedgerPageProvider.notifier).state = page - 1 : null,
                ),
                Text('Page ${page + 1} of ${pages < 1 ? 1 : pages}', style: TropaText.meta(subCol)),
                IconButton(
                  tooltip: 'Older',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: page + 1 < pages ? () => ref.read(duesLedgerPageProvider.notifier).state = page + 1 : null,
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

/// Ledger width from which receipts show as a table; narrower, each is a compact card.
const _ledgerTableWidth = 760.0;

final _dayFormat = DateFormat('MMM d');
final _dayYearFormat = DateFormat('MMM d, yyyy');
final _timeFormat = DateFormat('h:mm a');

/// Column widths of the ledger table, shared by the header and the rows.
const _ledgerFlex = (date: 10, who: 26, months: 16, method: 12, collector: 14, amount: 12);

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader();

  @override
  Widget build(BuildContext context) {
    final style = TropaText.tableHeader(TropaColors.textMedium(context));
    Widget cell(int flex, String text, {bool end = false}) => Expanded(
          flex: flex,
          child: Text(text, style: style, textAlign: end ? TextAlign.end : TextAlign.start),
        );
    return Container(
      color: TropaColors.chipOf(context),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          cell(_ledgerFlex.date, 'DATE'),
          cell(_ledgerFlex.who, 'HOUSEHOLD / MEMBER'),
          cell(_ledgerFlex.months, 'MONTHS'),
          cell(_ledgerFlex.method, 'METHOD'),
          cell(_ledgerFlex.collector, 'COLLECTED BY'),
          cell(_ledgerFlex.amount, 'AMOUNT', end: true),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// One ledger receipt: a table row when [wide], otherwise a compact card. Tapping opens the
/// receipt; Void and Delete sit in its ⋯ menu.
class _ReceiptRow extends ConsumerWidget {
  final DuesReceipt receipt;
  final bool wide;

  const _ReceiptRow({required this.receipt, required this.wide});

  Future<void> _void(BuildContext context, WidgetRef ref) async {
    final reason = await promptText(
      context,
      title: 'Void this receipt?',
      label: 'Reason (e.g. wrong household, duplicate entry)',
      confirmLabel: 'Void receipt',
      upperCase: true,
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await ref.read(supabaseServiceProvider).voidDuesReceipt(receipt.id, reason.trim());
      if (context.mounted) showSettingsMessage(context, 'Receipt voided. The months are unpaid again.');
    } catch (e) {
      if (context.mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Delete this receipt?',
      message: 'The record is removed permanently. Prefer Void to keep an audit trail.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(supabaseServiceProvider).deleteDuesReceipt(receipt.id);
  }

  void _open(BuildContext context) =>
      showTropaDialog<void>(context: context, builder: (_) => _ReceiptDialog(receipt: receipt, title: 'Receipt'));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final r = receipt;
    final who =
        r.householdName != null && r.memberCount > 1 ? r.householdName! : r.memberNames;
    final place = [
      if (r.barangay != null) r.barangay!,
      if (r.purok != null && r.purok!.isNotEmpty) r.purok!,
      if (r.memberCount > 1) '${r.memberCount} members',
    ].join(' · ');
    final paid = toPh(r.paymentDate);
    final date = paid.year == phToday().year ? _dayFormat.format(paid) : _dayYearFormat.format(paid);
    // Imported receipts carry a date only; their midnight is not a real time.
    final time = paid.hour == 0 && paid.minute == 0 ? null : _timeFormat.format(paid);
    final amount = Text(
      _peso.format(r.total),
      textAlign: TextAlign.end,
      style: TropaText.bodyStrong(r.isVoid ? subCol : TropaColors.secondaryStrongOf(context)).copyWith(
        decoration: r.isVoid ? TextDecoration.lineThrough : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final menu = PopupMenuButton<String>(
      tooltip: 'Receipt actions',
      icon: Icon(Icons.more_horiz, size: 18, color: subCol),
      onSelected: (v) => switch (v) {
        'void' => _void(context, ref),
        'delete' => _delete(context, ref),
        _ => _open(context),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'view', child: Text('View receipt')),
        if (!r.isVoid) const PopupMenuItem(value: 'void', child: Text('Void receipt')),
        if (canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete receipt', style: TextStyle(color: TropaColors.errorOf(context))),
          ),
      ],
    );
    Widget two(String top, String? bottom, {TextStyle? topStyle}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(top, style: topStyle ?? TropaText.body(textCol), overflow: TextOverflow.ellipsis),
            if (bottom != null && bottom.isNotEmpty)
              Text(bottom, style: TropaText.caption(subCol), overflow: TextOverflow.ellipsis),
          ],
        );
    final voidLine = r.isVoid ? 'VOID${r.voidReason != null ? ' · ${r.voidReason}' : ''}' : null;

    if (!wide) {
      return InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(who, style: TropaText.bodyStrong(textCol), overflow: TextOverflow.ellipsis),
                    Text(
                      [receiptMonthsLabel(r), '$date${time == null ? '' : ' $time'}', r.paymentMethod].join(' · '),
                      style: TropaText.caption(subCol),
                    ),
                    if (voidLine != null) Text(voidLine, style: TropaText.caption(TropaColors.errorOf(context))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              amount,
              menu,
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
        child: Row(
          children: [
            Expanded(flex: _ledgerFlex.date, child: two(date, time, topStyle: TropaText.meta(textCol))),
            Expanded(
              flex: _ledgerFlex.who,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: two(who, voidLine ?? place, topStyle: TropaText.bodyStrong(textCol)),
              ),
            ),
            Expanded(
              flex: _ledgerFlex.months,
              child: two(receiptMonthRange(r), r.memberCount > 1 ? '${r.monthsCovered} member-months' : null),
            ),
            Expanded(
              flex: _ledgerFlex.method,
              child: two(r.paymentMethod, r.referenceNumber == null ? null : 'Ref ${r.referenceNumber}'),
            ),
            Expanded(flex: _ledgerFlex.collector, child: two(_titleCase(r.collectedBy), null)),
            Expanded(flex: _ledgerFlex.amount, child: Align(alignment: Alignment.centerRight, child: amount)),
            SizedBox(width: 40, child: menu),
          ],
        ),
      ),
    );
  }
}

String _titleCase(String s) =>
    s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

/// A small labelled number in the ledger's totals strip.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color? color;

  const _StatTile({required this.label, required this.value, this.caption, this.color});

  @override
  Widget build(BuildContext context) {
    final subCol = TropaColors.textMedium(context);
    return _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TropaText.caption(subCol)),
            Text(
              value,
              style: TropaText.kpi(color ?? TropaColors.textHigh(context), size: 18)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            if (caption != null) Text(caption!, style: TropaText.caption(subCol)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Shared bits
// ==========================================
class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Surface({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TropaColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TropaColors.borderOf(context)),
      ),
      child: child,
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;

  const _Notice(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TropaText.meta(color))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: TropaColors.textDisabled(context)),
            const SizedBox(height: 12),
            Text(title, style: TropaText.sectionTitle(TropaColors.textHigh(context))),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: TropaText.meta(TropaColors.textMedium(context))),
          ],
        ),
      ),
    );
  }
}
