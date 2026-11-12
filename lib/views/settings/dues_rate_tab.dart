import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../core/dues_math.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dues_provider.dart';
import '../../widgets/form_fields.dart';
import 'settings_common.dart';

/// The one monthly dues rate per member and the fund split, each with its history. Both apply from
/// their effective month onward; earlier months keep what was in force then.
class DuesRateTab extends ConsumerStatefulWidget {
  const DuesRateTab({super.key});

  @override
  ConsumerState<DuesRateTab> createState() => _DuesRateTabState();
}

class _DuesRateTabState extends ConsumerState<DuesRateTab> {
  static final _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  final _amount = TextEditingController();
  late final _month = TextEditingController(text: monthKey(currentMonthIndex()));
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _month.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    final month = _month.text.trim();
    if (amount == null || amount < 0) {
      showSettingsMessage(context, 'Enter the monthly amount per member.', error: true);
      return;
    }
    if (parseMonthKey(month) == null) {
      showSettingsMessage(context, 'Effective month must look like 2026-10.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(supabaseServiceProvider).saveDuesRate(amount: amount, effectiveMonth: month);
      _amount.clear();
      if (mounted) showSettingsMessage(context, 'Dues rate saved.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(DuesRate rate) async {
    final ok = await confirmAction(
      context,
      title: 'Remove this rate?',
      message: 'Months from ${monthLabel(parseMonthKey(rate.effectiveMonth) ?? 0)} will use the previous rate. '
          'Amounts already recorded do not change.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(supabaseServiceProvider).deleteDuesRate(rate);
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final rates = ref.watch(duesRatesProvider).value ?? const <DuesRate>[];
    final current = currentMonthIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rateCard(p, rates, current),
        const SizedBox(height: 16),
        const _FundAllocationCard(),
      ],
    );
  }

  Widget _rateCard(SettingsPalette p, List<DuesRate> rates, int current) {
    return SettingsCard(
      title: 'Dues Rate',
      subtitle: 'Monthly dues per cooperative member, the same for every barangay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rates.isEmpty ? 'No rate set — the Dues page cannot bill anyone yet.' : 'Current: ${_peso.format(rateForMonth(current, rates))} per member per month',
            style: p.bodyStrong,
          ),
          const SizedBox(height: 4),
          Text(
            'A rate applies from its effective month until the next one. The earliest rate also covers months before it.',
            style: p.caption,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 180,
                child: LabeledField(
                  label: 'Amount (PHP)',
                  child: TextField(
                    controller: _amount,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.formField(context, hint: '20.00'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: LabeledField(
                  label: 'Effective month (YYYY-MM)',
                  child: TextField(
                    controller: _month,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.formField(context),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save rate'),
              ),
            ],
          ),
          if (rates.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('HISTORY', style: p.label),
            const SizedBox(height: 4),
            for (final r in rates.reversed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_peso.format(r.amount), style: p.bodyStrong),
                subtitle: Text(
                  'From ${monthLabel(parseMonthKey(r.effectiveMonth) ?? 0)}${r.createdBy == null ? '' : ' · set by ${r.createdBy}'}',
                  style: p.meta,
                ),
                trailing: IconButton(
                  tooltip: 'Remove rate',
                  icon: Icon(Icons.delete_outline, size: 18, color: p.error),
                  onPressed: () => _delete(r),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// How collected dues split into funds, with its history. Like the rate, a split applies from its
/// effective month onward, so past collections keep the split in force when they were paid.
class _FundAllocationCard extends ConsumerStatefulWidget {
  const _FundAllocationCard();

  @override
  ConsumerState<_FundAllocationCard> createState() => _FundAllocationCardState();
}

class _FundAllocationCardState extends ConsumerState<_FundAllocationCard> {
  late final _fields = {
    for (final f in DuesFund.values) f: TextEditingController()..addListener(() => setState(() {})),
  };
  late final _month = TextEditingController(text: monthKey(currentMonthIndex()));
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _month.dispose();
    super.dispose();
  }

  static String _percentText(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Map<DuesFund, double?> get _percents => {for (final e in _fields.entries) e.key: double.tryParse(e.value.text.trim())};

  Future<void> _save() async {
    final month = _month.text.trim();
    if (parseMonthKey(month) == null) {
      showSettingsMessage(context, 'Effective month must look like 2026-10.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(supabaseServiceProvider).saveDuesAllocation(
            percents: {for (final e in _percents.entries) e.key: e.value ?? 0},
            effectiveMonth: month,
          );
      if (mounted) showSettingsMessage(context, 'Fund split saved.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(DuesAllocation a) async {
    final ok = await confirmAction(
      context,
      title: 'Remove this split?',
      message: 'Dues paid from ${monthLabel(parseMonthKey(a.effectiveMonth) ?? 0)} will use the previous split.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(supabaseServiceProvider).deleteDuesAllocation(a);
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  String _splitText(Map<DuesFund, double> percents) =>
      [for (final f in DuesFund.values) '${f.label} ${percentLabel(percents[f] ?? 0)}'].join(' · ');

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final allocationsAsync = ref.watch(duesAllocationsProvider);
    final allocations = allocationsAsync.value ?? const <DuesAllocation>[];
    final inForce = allocationForMonth(currentMonthIndex(), allocations);
    // Start the form from the split in force, once it has loaded.
    if (!_prefilled && allocationsAsync.hasValue) {
      _prefilled = true;
      for (final f in DuesFund.values) {
        _fields[f]!.text = _percentText(inForce[f] ?? 0);
      }
    }
    final percents = _percents;
    final valid = percents.values.every((v) => v != null && v >= 0);
    final total = percents.values.fold<double>(0, (sum, v) => sum + (v ?? 0));
    final balanced = valid && (total - 100).abs() < 0.001;

    return SettingsCard(
      title: 'Fund Allocation',
      subtitle: 'How collected dues are divided, shown on the Dues ledger and its printed report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current: ${_splitText(inForce)}', style: p.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'Each payment is divided with the split in force on its payment date, so changing it never changes '
            'past reports. The percentages must add up to 100%.',
            style: p.caption,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final f in DuesFund.values)
                SizedBox(
                  width: 180,
                  child: LabeledField(
                    label: '${f.label} (%)',
                    child: TextField(
                      controller: _fields[f],
                      style: TropaStyles.fieldText(context),
                      decoration: TropaStyles.formField(context),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 180,
                child: LabeledField(
                  label: 'Effective month (YYYY-MM)',
                  child: TextField(
                    controller: _month,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.formField(context),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _saving || !balanced ? null : _save,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save split'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  valid ? 'Total ${percentLabel(total)}' : 'Enter a number for every fund',
                  style: p.bodyStrong.copyWith(color: balanced ? null : p.error),
                ),
              ),
            ],
          ),
          if (allocations.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('HISTORY', style: p.label),
            const SizedBox(height: 4),
            for (final a in allocations.reversed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_splitText(a.percents), style: p.bodyStrong),
                subtitle: Text(
                  'From ${monthLabel(parseMonthKey(a.effectiveMonth) ?? 0)}${a.createdBy == null ? '' : ' · set by ${a.createdBy}'}',
                  style: p.meta,
                ),
                trailing: IconButton(
                  tooltip: 'Remove split',
                  icon: Icon(Icons.delete_outline, size: 18, color: p.error),
                  onPressed: () => _delete(a),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
