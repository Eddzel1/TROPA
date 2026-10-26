import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
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
        void openPrint() => showDialog<void>(context: context, builder: (_) => _PrintSheetDialog(scope: scope!));
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(duesSearchProvider.notifier).update((s) => s.copyWith(query: value.trim()));
    });
  }

  void _open(DuesSelection sel, {required bool wide}) {
    ref.read(duesSelectionProvider.notifier).state = sel;
    if (wide) return;
    showDialog(
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
          SizedBox(height: short ? 8 : 12),
          TextField(
            inputFormatters: const [UpperCaseFormatter()],
            textCapitalization: TextCapitalization.characters,
            controller: _searchCtrl,
            style: TropaStyles.fieldText(context),
            decoration: TropaStyles.filterField(
              context,
              hint: search.mode == DuesSearchMode.household ? 'Household or member name…' : 'Member name…',
              search: true,
            ),
            onChanged: _search,
          ),
          SizedBox(height: short ? 8 : 12),
          Expanded(
            child: search.mode == DuesSearchMode.household
                ? _HouseholdResults(
                    selectedId: selection?.id,
                    onOpen: (id) => _open((mode: DuesSearchMode.household, id: id), wide: wide))
                : _MemberResults(
                    selectedId: selection?.id,
                    onOpen: (id) => _open((mode: DuesSearchMode.member, id: id), wide: wide)),
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
              child: selection == null
                  ? const _EmptyState(
                      icon: Icons.touch_app_outlined,
                      title: 'Choose a household or member',
                      message: 'Their unpaid months and amount due appear here.',
                    )
                  : _PaymentPanel(key: ValueKey(selection), selection: selection),
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

class _OwedLabel extends StatelessWidget {
  final int months;
  final double amount;

  const _OwedLabel({required this.months, required this.amount});

  @override
  Widget build(BuildContext context) {
    if (months <= 0) {
      return TropaBadge('Up to date', color: TropaColors.secondaryStrongOf(context), icon: Icons.check_circle_outline);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(_peso.format(amount), style: TropaText.bodyStrong(TropaColors.errorOf(context))),
        Text('$months mo unpaid', style: TropaText.caption(TropaColors.textMedium(context))),
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

  Future<void> _record(List<DuesRate> rates) async {
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
      await showDialog(context: context, builder: (_) => _ReceiptDialog(receipt: receipt));
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
                      child: const Text('All owed'),
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
                    onPressed: canRecord ? () => _record(rates) : null,
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

  const _ReceiptDialog({required this.receipt});

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
      title: const Text('Payment recorded'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_peso.format(receipt.total), style: TropaText.kpi(TropaColors.secondaryStrongOf(context))),
            const SizedBox(height: 12),
            if (receipt.householdName != null) line('Household', receipt.householdName!),
            line('Members', receipt.memberNames),
            line('Months', _ReceiptTile.monthsLabel(receipt)),
            line('Method', receipt.paymentMethod),
            if (receipt.referenceNumber != null) line('Reference', receipt.referenceNumber!),
            line('Date', formatPh(_dateTimeFormat, receipt.paymentDate)),
            line('Collected by', receipt.collectedBy),
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
  late final _searchCtrl = TextEditingController(text: ref.read(duesLedgerQueryProvider));
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(duesLedgerPageProvider.notifier).state = 0;
      ref.read(duesLedgerQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(duesLedgerPageProvider);
    final receiptsAsync = ref.watch(duesReceiptsProvider);
    final totals = ref.watch(duesLedgerTotalsProvider).value;
    final hasQuery = ref.watch(duesLedgerQueryProvider).isNotEmpty;

    return LayoutBuilder(builder: (context, constraints) {
    // With the keyboard up, the totals and pager give their room to the search box and receipts.
    final short = constraints.maxHeight < _shortTabHeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          inputFormatters: const [UpperCaseFormatter()],
          textCapitalization: TextCapitalization.characters,
          controller: _searchCtrl,
          style: TropaStyles.fieldText(context),
          decoration: TropaStyles.filterField(context,
              hint: 'Search by name, household, reference or month (YYYY-MM)…', search: true),
          onChanged: _search,
        ),
        SizedBox(height: short ? 8 : 12),
        if (totals != null && !short) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TotalTile(
                  label: hasQuery ? 'Total collected (matching search)' : 'Total collected',
                  amount: totals.total,
                  caption: '${totals.receipts} receipt${totals.receipts == 1 ? '' : 's'} · voided receipts excluded'),
              _TotalTile(label: 'Collected in ${monthLabel(currentMonthIndex())}', amount: totals.thisMonth),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: receiptsAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading ledger: $e')),
            data: (receipts) => receipts.isEmpty
                ? const _EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No receipts',
                    message: 'Payments recorded on the Collect tab appear here.',
                  )
                : _Surface(
                    child: ListView.separated(
                      itemCount: receipts.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: TropaColors.borderOf(context)),
                      itemBuilder: (_, i) => _ReceiptTile(receipt: receipts[i]),
                    ),
                  ),
          ),
        ),
        if (!short) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Newer',
              icon: const Icon(Icons.chevron_left),
              onPressed: page > 0 ? () => ref.read(duesLedgerPageProvider.notifier).state = page - 1 : null,
            ),
            Text('Page ${page + 1}', style: TropaText.meta(TropaColors.textMedium(context))),
            IconButton(
              tooltip: 'Older',
              icon: const Icon(Icons.chevron_right),
              onPressed: (receiptsAsync.value?.length ?? 0) >= 50
                  ? () => ref.read(duesLedgerPageProvider.notifier).state = page + 1
                  : null,
            ),
          ],
        ),
        ],
      ],
    );
    });
  }
}

class _ReceiptTile extends ConsumerWidget {
  final DuesReceipt receipt;

  const _ReceiptTile({required this.receipt});

  static String monthsLabel(DuesReceipt r) {
    final first = parseMonthKey(r.firstMonth);
    final last = parseMonthKey(r.lastMonth);
    final range = first == null ? (r.firstMonth ?? '') : monthRangeLabel(first, (last ?? first) - first + 1);
    return r.memberCount > 1 ? '$range · ${r.monthsCovered} member-months' : range;
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final r = receipt;
    final who =
        r.householdName != null && r.memberCount > 1 ? '${r.householdName} (${r.memberCount} members)' : r.memberNames;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading:
          Icon(r.isVoid ? Icons.block : Icons.receipt, color: r.isVoid ? subCol : TropaColors.secondaryOf(context)),
      title: Wrap(
        spacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _peso.format(r.total),
            style: TropaText.sectionTitle(r.isVoid ? subCol : TropaColors.secondaryStrongOf(context)).copyWith(
              decoration: r.isVoid ? TextDecoration.lineThrough : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(who, style: TropaText.bodyStrong(textCol)),
          if (r.isVoid) TropaBadge('VOID', color: TropaColors.errorOf(context)),
        ],
      ),
      subtitle: Text(
        [
          monthsLabel(r),
          if (r.barangay != null) r.barangay!,
          r.paymentMethod,
          if (r.referenceNumber != null) 'Ref ${r.referenceNumber}',
          formatPh(_dateTimeFormat, r.paymentDate),
          if (r.collectedBy.isNotEmpty) 'by ${r.collectedBy}',
          if (r.isVoid && r.voidReason != null) 'Voided: ${r.voidReason}',
        ].join(' · '),
        style: TropaText.caption(subCol),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!r.isVoid)
            IconButton(
              tooltip: 'Void receipt',
              icon: const Icon(Icons.block, size: 18),
              onPressed: () => _void(context, ref),
            ),
          if (canDelete)
            IconButton(
              tooltip: 'Delete receipt',
              icon: Icon(Icons.delete_outline, size: 18, color: TropaColors.errorOf(context)),
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  final String label;
  final double amount;
  final String? caption;

  const _TotalTile({required this.label, required this.amount, this.caption});

  @override
  Widget build(BuildContext context) {
    final subCol = TropaColors.textMedium(context);
    return _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TropaText.meta(subCol)),
            Text(
              _peso.format(amount),
              style: TropaText.kpi(TropaColors.secondaryStrongOf(context), size: 22)
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
