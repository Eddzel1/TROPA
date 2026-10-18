import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/dues_math.dart';
import '../core/ph_time.dart';
import '../models/models.dart';

/// Asks for a corrected membership date for [members] (one member, or a whole household), showing
/// how each one's unpaid months change. Returns the chosen date, or null when cancelled.
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
  static final _dateFormat = DateFormat('MMM d, yyyy');
  late DateTime? _date = widget.members.length == 1 ? widget.members.first.membershipDate : null;

  Future<void> _pick() async {
    final today = phToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(1990),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _owed(DuesMember m, DateTime? date) {
    if (!m.isCoopMember) return 'Not billed';
    if (date == null) return 'No date';
    final b = balanceFor(
      DuesMember(
        id: m.id, firstname: m.firstname, lastname: m.lastname, householdId: m.householdId,
        lgu: m.lgu, barangay: m.barangay, purok: m.purok, membershipDate: date,
        isCoopMember: m.isCoopMember, monthsPaid: m.monthsPaid,
      ),
      widget.rates,
    )!;
    return b.statusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subCol = TropaColors.textMedium(context);
    final single = widget.members.length == 1;

    return AlertDialog(
      title: Text(single ? 'Membership date' : 'Set membership date for ${widget.members.length} members'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dues are billed from the month of this date. Payments already recorded stay and are '
              'applied from the new start month.',
              style: TropaText.meta(subCol),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: TropaStyles.secondaryAction(context),
              icon: const Icon(Icons.event, size: 18),
              label: Text(_date == null ? 'Choose date' : formatDate(_date!)),
              onPressed: _pick,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
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
                                  m.membershipDate == null ? 'No membership date' : 'Now ${formatDate(m.membershipDate!)}',
                                  style: TropaText.caption(subCol),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${_owed(m, m.membershipDate)}  →  ${_owed(m, _date)}',
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _date == null ? null : () => Navigator.pop(context, _date),
          child: const Text('Save date'),
        ),
      ],
    );
  }

  static String formatDate(DateTime d) => _dateFormat.format(d);
}
