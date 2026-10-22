import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../core/dues_math.dart';
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

/// Sets a barangay's dues starting month (Settings › Locations & Barangays). New members encoded
/// there adopt it; the dialog also offers to apply it to the members already there. Returns a
/// message to show when something was saved, or null when cancelled.
Future<String?> showBarangayStartMonthDialog(BuildContext context, {required Location location}) {
  return showDialog<String>(context: context, builder: (_) => _BarangayStartMonthDialog(location: location));
}

class _BarangayStartMonthDialog extends ConsumerStatefulWidget {
  final Location location;

  const _BarangayStartMonthDialog({required this.location});

  @override
  ConsumerState<_BarangayStartMonthDialog> createState() => _BarangayStartMonthDialogState();
}

class _BarangayStartMonthDialogState extends ConsumerState<_BarangayStartMonthDialog> {
  late int? _month = parseMonthKey(widget.location.duesStartMonth);
  ({int total, int changing})? _count;
  bool _saving = false;

  /// Bumped on each change so a slow count for an earlier month doesn't overwrite a newer one.
  int _countRequest = 0;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final m = _month;
    final request = ++_countRequest;
    setState(() => _count = null);
    if (m == null) return;
    final count = await ref
        .read(supabaseServiceProvider)
        .countBarangayMembers(lgu: widget.location.lgu, barangay: widget.location.barangay, monthIndex: m);
    if (mounted && request == _countRequest) setState(() => _count = count);
  }

  Future<void> _save({required bool applyToExisting}) async {
    final m = _month!;
    final l = widget.location;
    final service = ref.read(supabaseServiceProvider);
    setState(() => _saving = true);
    try {
      await service.setLocationStartMonth(l, monthKey(m));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSettingsMessage(context, errorMessage(e), error: true);
      return;
    }
    var message = 'New members in ${l.barangay} will start in ${monthLabel(m)}.';
    if (applyToExisting) {
      try {
        final changed = await service.setBarangayMembershipMonth(lgu: l.lgu, barangay: l.barangay, monthIndex: m);
        message = '${l.barangay} starts in ${monthLabel(m)}; updated $changed existing member${changed == 1 ? '' : 's'}. '
            'The new months appear as they sync.';
      } catch (e) {
        message = '${l.barangay} starts in ${monthLabel(m)} for new members, but existing members were not '
            'updated: ${errorMessage(e)}';
      }
    }
    if (mounted) Navigator.pop(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final subCol = TropaColors.textMedium(context);
    final textCol = TropaColors.textHigh(context);
    final l = widget.location;
    final count = _count;
    final m = _month;

    return AlertDialog(
      title: Text('Dues starting month · ${l.barangay}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every new member encoded in ${l.barangay} gets this month as their membership date, so '
                'their dues count from it.',
                style: TropaText.meta(subCol),
              ),
              const SizedBox(height: 12),
              MonthPicker(
                selected: m,
                onChanged: (v) {
                  _month = v;
                  _refreshCount();
                },
              ),
              const SizedBox(height: 12),
              if (m != null)
                Text(
                  count == null
                      ? 'Counting members already in ${l.barangay}…'
                      : count.changing == 0
                          ? 'All ${count.total} member${count.total == 1 ? '' : 's'} already in ${l.barangay} start in ${monthLabel(m)}.'
                          : '${count.changing} of the ${count.total} members already in ${l.barangay} have a different '
                              'month. You can update them too (needs internet).',
                  style: TropaText.body(textCol),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        OutlinedButton(
          onPressed: _saving || m == null ? null : () => _save(applyToExisting: false),
          child: const Text('Save for new members only'),
        ),
        if (count != null && count.changing > 0)
          FilledButton(
            onPressed: _saving ? null : () => _save(applyToExisting: true),
            child: Text('Save and update ${count.changing} existing'),
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
