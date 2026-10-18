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

/// The one monthly dues rate per member, with its history. A new rate applies from its effective
/// month onward; earlier months keep the rate that was in force then.
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
