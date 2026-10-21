import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../core/dues_math.dart';
import '../core/geo.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../views/settings/settings_common.dart';

/// "Jul 2026" for a membership date; only the month matters for dues.
String membershipMonthLabel(DateTime date) => monthLabel(monthIndexOf(date));

/// Asks for a corrected membership month for [members] (one member, or a whole household),
/// showing how each one's unpaid months change. Returns the 1st of the chosen month, or null
/// when cancelled.
Future<DateTime?> showMembershipDateDialog(
  BuildContext context, {
  required List<DuesMember> members,
  required List<DuesRate> rates,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MembershipDateDialog(members: members, rates: rates),
  );
}

class _MembershipDateDialog extends StatefulWidget {
  final List<DuesMember> members;
  final List<DuesRate> rates;

  const _MembershipDateDialog({required this.members, required this.rates});

  @override
  State<_MembershipDateDialog> createState() => _MembershipDateDialogState();
}

class _MembershipDateDialogState extends State<_MembershipDateDialog> {
  late int? _month = switch (widget.members) {
    [DuesMember(membershipDate: final DateTime d)] => monthIndexOf(d),
    _ => null,
  };

  String _owed(DuesMember m, int? month) {
    if (!m.isCoopMember) return 'Not billed';
    if (month == null) return 'No date';
    return DuesBalance(
      startMonth: month,
      monthsPaid: m.monthsPaid,
      currentMonth: currentMonthIndex(),
      rates: widget.rates,
    ).statusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final single = widget.members.length == 1;

    return AlertDialog(
      title: Text(single ? 'Membership month' : 'Set membership month for ${widget.members.length} members'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dues are billed from this month. Payments already recorded stay and are applied from '
                'the new start month.',
                style: TropaText.meta(subCol),
              ),
              const SizedBox(height: 12),
              MonthPicker(selected: _month, onChanged: (m) => setState(() => _month = m)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in widget.members)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.fullName, style: TropaText.bodyStrong(textCol)),
                                  Text(
                                    m.membershipDate == null
                                        ? 'No membership date'
                                        : 'Now ${membershipMonthLabel(m.membershipDate!)}',
                                    style: TropaText.caption(subCol),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${_owed(m, m.membershipDate == null ? null : monthIndexOf(m.membershipDate!))}'
                                '  →  ${_owed(m, _month)}',
                                style: TropaText.caption(subCol),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _month == null ? null : () => Navigator.pop(context, DateTime(_month! ~/ 12, _month! % 12 + 1, 1)),
          child: Text(_month == null ? 'Save' : 'Save ${monthLabel(_month!)}'),
        ),
      ],
    );
  }
}

/// Sets the membership month of every member of one barangay. [barangays] are the ones the user
/// may choose from. Returns how many members changed, or null when cancelled.
Future<int?> showBarangayMembershipDialog(BuildContext context, {required List<LocationOption> barangays}) {
  return showDialog<int>(context: context, builder: (_) => _BarangayMembershipDialog(barangays: barangays));
}

class _BarangayMembershipDialog extends ConsumerStatefulWidget {
  final List<LocationOption> barangays;

  const _BarangayMembershipDialog({required this.barangays});

  @override
  ConsumerState<_BarangayMembershipDialog> createState() => _BarangayMembershipDialogState();
}

class _BarangayMembershipDialogState extends ConsumerState<_BarangayMembershipDialog> {
  late LocationOption? _barangay = widget.barangays.length == 1 ? widget.barangays.first : null;
  int? _month;
  ({int total, int changing})? _count;
  bool _saving = false;

  /// Bumped on each change so a slow count for an earlier choice doesn't overwrite a newer one.
  int _countRequest = 0;

  Future<void> _refreshCount() async {
    final b = _barangay, m = _month;
    final request = ++_countRequest;
    setState(() => _count = null);
    if (b == null || m == null) return;
    final count = await ref
        .read(supabaseServiceProvider)
        .countBarangayMembers(lgu: b.lgu, barangay: b.barangay, monthIndex: m);
    if (mounted && request == _countRequest) setState(() => _count = count);
  }

  Future<void> _save() async {
    final b = _barangay!, m = _month!, count = _count!;
    final ok = await confirmAction(
      context,
      title: 'Set ${monthLabel(m)} for ${count.total} members?',
      message: 'Every member registered in ${b.barangay} gets ${monthLabel(m)} as their membership month, '
          'replacing the month they have now. ${count.changing} of them change. Their unpaid months are '
          'recalculated from ${monthLabel(m)}.',
      confirmLabel: 'Set ${monthLabel(m)}',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      final changed = await ref
          .read(supabaseServiceProvider)
          .setBarangayMembershipMonth(lgu: b.lgu, barangay: b.barangay, monthIndex: m);
      if (mounted) Navigator.pop(context, changed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCol = TropaColors.textMedium(context);
    final count = _count;
    final canSave = !_saving && _barangay != null && _month != null && count != null && count.changing > 0;

    return AlertDialog(
      title: const Text('Set membership month for a barangay'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every member registered in the barangay gets this month, replacing the month they have now. '
                'Use it when a whole barangay joined together.',
                style: TropaText.meta(subCol),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LocationOption>(
                initialValue: _barangay,
                isExpanded: true,
                hint: const Text('Choose barangay'),
                style: TropaStyles.fieldText(context),
                decoration: TropaStyles.formField(context),
                items: [
                  for (final b in widget.barangays)
                    DropdownMenuItem(value: b, child: Text('${b.barangay}, ${b.lgu}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (b) {
                  _barangay = b;
                  _refreshCount();
                },
              ),
              const SizedBox(height: 12),
              MonthPicker(
                selected: _month,
                onChanged: (m) {
                  _month = m;
                  _refreshCount();
                },
              ),
              const SizedBox(height: 12),
              if (_barangay != null && _month != null)
                Text(
                  count == null
                      ? 'Counting members…'
                      : count.total == 0
                          ? 'No members are registered in ${_barangay!.barangay}.'
                          : '${count.total} member${count.total == 1 ? '' : 's'} in ${_barangay!.barangay} · '
                              '${count.changing} will change',
                  style: TropaText.bodyStrong(TropaColors.textHigh(context)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: canSave ? _save : null,
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.edit_calendar, size: 16),
          label: const Text('Set month'),
        ),
      ],
    );
  }
}

/// Year with ‹ › arrows over a grid of months. Months after the current month can't be picked.
class MonthPicker extends StatefulWidget {
  /// Month index (see [monthIndexOf]), or null for none.
  final int? selected;
  final ValueChanged<int> onChanged;

  const MonthPicker({super.key, required this.selected, required this.onChanged});

  @override
  State<MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  static const _firstYear = 1990;
  late final int _current = currentMonthIndex();
  late int _year = (widget.selected ?? _current) ~/ 12;

  @override
  Widget build(BuildContext context) {
    final primary = TropaColors.primaryOf(context);
    final textCol = TropaColors.textHigh(context);
    final maxYear = _current ~/ 12;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: TropaColors.borderOf(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous year',
                icon: const Icon(Icons.chevron_left),
                onPressed: _year > _firstYear ? () => setState(() => _year--) : null,
              ),
              Expanded(child: Text('$_year', textAlign: TextAlign.center, style: TropaText.sectionTitle(textCol))),
              IconButton(
                tooltip: 'Next year',
                icon: const Icon(Icons.chevron_right),
                onPressed: _year < maxYear ? () => setState(() => _year++) : null,
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < 12; i++)
                Builder(builder: (context) {
                  final month = _year * 12 + i;
                  final selected = month == widget.selected;
                  final enabled = month <= _current;
                  return TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: selected ? primary : null,
                      foregroundColor: selected ? TropaColors.onPrimaryOf(context) : textCol,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: enabled ? () => widget.onChanged(month) : null,
                    child: Text(monthLabel(month).split(' ').first),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}
