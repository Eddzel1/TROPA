import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/motion.dart';
import '../core/ph_time.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/review_flags.dart';
import 'form_fields.dart';
import 'household_view_dialog.dart';

final _dateFmt = DateFormat('MMM d, y');

/// Colors for matched people; the same color (and number) in every column = likely one person.
const _matchColors = [
  Color(0xFFD9480F),
  Color(0xFF1C7ED6),
  Color(0xFF2B8A3E),
  Color(0xFF9C36B5),
  Color(0xFFE8590C),
  Color(0xFF0B7285),
  Color(0xFFC2255C),
  Color(0xFF5F3DC4),
];

/// Side-by-side view of a flagged household and the households it shares people with (from the
/// For Review page). Each column lists a household's members; people found in more than one column
/// (same rule as the review page, see reviewSamePerson) share a numbered color.
class HouseholdCompareDialog extends ConsumerStatefulWidget {
  /// The reviewed household first, then the ones it matched.
  final List<String> householdIds;

  const HouseholdCompareDialog({super.key, required this.householdIds});

  @override
  ConsumerState<HouseholdCompareDialog> createState() => _HouseholdCompareDialogState();
}

typedef _Column = ({Household household, List<Map<String, dynamic>> members});

class _HouseholdCompareDialogState extends ConsumerState<HouseholdCompareDialog> {
  late Future<(List<_Column>, Map<String, int>)> _data = _load();

  Future<(List<_Column>, Map<String, int>)> _load() async {
    final service = ref.read(supabaseServiceProvider);
    final columns = <_Column>[];
    for (final id in {...widget.householdIds}) {
      final h = await service.getHouseholdById(id);
      if (h == null) continue;
      columns.add((household: h, members: await service.getHouseholdMemberRows(id)));
    }
    return (columns, _groups(columns));
  }

  /// Member id -> group number (1, 2, …) for people matched across columns.
  Map<String, int> _groups(List<_Column> columns) {
    final all = [
      for (final c in columns)
        for (final m in c.members) m,
    ];
    final parent = {for (final m in all) m['id'].toString(): m['id'].toString()};
    String find(String x) => parent[x] == x ? x : (parent[x] = find(parent[x]!));
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        final a = all[i], b = all[j];
        if (a['household_id'] == b['household_id']) continue;
        if (reviewSamePerson(a, b)) parent[find(a['id'].toString())] = find(b['id'].toString());
      }
    }
    final sizes = <String, int>{};
    for (final m in all) {
      final r = find(m['id'].toString());
      sizes[r] = (sizes[r] ?? 0) + 1;
    }
    // Number groups in the order they appear, reading the columns left to right.
    final numbers = <String, int>{};
    final result = <String, int>{};
    for (final m in all) {
      final r = find(m['id'].toString());
      if ((sizes[r] ?? 0) < 2) continue;
      result[m['id'].toString()] = numbers.putIfAbsent(r, () => numbers.length + 1);
    }
    return result;
  }

  void _refresh() => setState(() => _data = _load());

  Future<void> _open(Household h) async {
    await showTropaDialog<void>(context: context, builder: (_) => HouseholdViewDialog(household: h));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final size = MediaQuery.of(context).size;
    final compact = TropaBreakpoints.isCompact(size.width);

    return Dialog(
      backgroundColor: TropaColors.cardOf(context),
      insetPadding: EdgeInsets.all(compact ? 8 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: size.width * 0.95,
        height: size.height * 0.88,
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Compare households', style: TropaText.dialogTitle(textCol))),
                  IconButton(
                    tooltip: 'Check again',
                    icon: Icon(Icons.refresh, color: subtextCol),
                    onPressed: _refresh,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: subtextCol),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Same color and number = likely the same person in more than one household. '
                'The first column is the household being reviewed.',
                style: TropaText.meta(subtextCol),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<(List<_Column>, Map<String, int>)>(
                  future: _data,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Could not load: ${snap.error}', style: TropaText.body(textCol)));
                    }
                    final (columns, groups) = snap.data!;
                    if (columns.isEmpty) {
                      return Center(child: Text('These households could not be found.', style: TropaText.body(textCol)));
                    }
                    final matched = groups.values.toSet().length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matched == 0
                              ? 'No one appears in more than one of these households any more.'
                              : '$matched ${matched == 1 ? 'person appears' : 'people appear'} in more than one household.',
                          style: TropaText.bodyStrong(textCol),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final (i, c) in columns.indexed) ...[
                                    if (i > 0) const SizedBox(width: 12),
                                    SizedBox(width: compact ? 280 : 320, child: _column(c, groups, reviewed: i == 0)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(_Column c, Map<String, int> groups, {required bool reviewed}) {
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final primaryCol = TropaColors.primaryOf(context);
    final h = c.household;
    final place = [h.purok, h.barangay, h.lgu].where((s) => s.trim().isNotEmpty).join(', ');
    final shared = c.members.where((m) => groups.containsKey(m['id'].toString())).length;

    return Container(
      decoration: BoxDecoration(
        color: TropaColors.subtleOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: reviewed ? primaryCol : TropaColors.borderOf(context), width: reviewed ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reviewed) ...[
                  TropaBadge('BEING REVIEWED', color: primaryCol),
                  const SizedBox(height: 6),
                ],
                Text(h.householdName, style: TropaText.bodyStrong(textCol)),
                const SizedBox(height: 2),
                Text(place, style: TropaText.meta(subtextCol)),
                Text(
                  'Encoded ${formatPh(_dateFmt, h.createdDate)} by '
                  '${h.createdBy.trim().isEmpty ? '(unknown)' : h.createdBy}',
                  style: TropaText.meta(subtextCol),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${c.members.length} members · $shared shared',
                        style: TropaText.caption(subtextCol),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _open(h),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: Text('Open', style: TropaText.action()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: TropaColors.borderOf(context)),
          Expanded(
            child: c.members.isEmpty
                ? Center(child: Text('No active members', style: TropaText.meta(subtextCol)))
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: [for (final m in c.members) _member(m, groups[m['id'].toString()])],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _member(Map<String, dynamic> m, int? group) {
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final color = group == null ? null : _matchColors[(group - 1) % _matchColors.length];
    String s(String k) => (m[k]?.toString() ?? '').trim();
    final leader = m['is_household_leader'] == 1 || m['is_household_leader'] == true;
    final birth = s('birth_date').length >= 10 ? s('birth_date').substring(0, 10) : 'no birth date';
    final created = parsePh(s('created_date'));
    final name = '${s('lastname')}, ${s('firstname')}${s('middlename').isEmpty ? '' : ' ${s('middlename')}'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.12) ?? TropaColors.cardOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color ?? Colors.transparent, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (color != null) ...[
            CircleAvatar(
              radius: 11,
              backgroundColor: color,
              child: Text('$group',
                  style: TextStyle(color: TropaColors.onColor(color), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(name, style: TropaText.bodyStrong(textCol)),
                    if (leader) TropaBadge('HHL', color: TropaColors.secondaryStrongOf(context)),
                  ],
                ),
                Text('b. $birth', style: TropaText.meta(subtextCol)),
                Text(
                  'Encoded ${created == null ? 'unknown date' : formatPh(_dateFmt, created)}'
                  '${s('created_by').isEmpty ? '' : ' by ${s('created_by')}'}',
                  style: TropaText.caption(subtextCol),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
