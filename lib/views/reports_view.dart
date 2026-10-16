import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/reports_provider.dart';

class ReportsAnalyticsView extends ConsumerStatefulWidget {
  const ReportsAnalyticsView({super.key});

  @override
  ConsumerState<ReportsAnalyticsView> createState() => _ReportsAnalyticsViewState();
}

class _ReportsAnalyticsViewState extends ConsumerState<ReportsAnalyticsView> {
  int? _sortColumn;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(barangayReportProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final cardBg = isDark ? TropaColors.darkSurface1dp : Colors.white;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reports & Analytics', style: TropaText.pageTitle(textCol)),
                    Text('Membership and voter averages by LGU and barangay', style: TropaText.meta(subtextCol)),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      style: TropaStyles.secondaryAction(context),
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Export CSV'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generated CSV Export for Barangay Registry.')),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      style: TropaStyles.primaryAction(context),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Print Official Report'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preparing PDF Print Roster for City Mayor & Cooperative Union...')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            reportAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading stats: $e', style: TextStyle(color: textCol)),
              data: (stats) {
                final total = _sum(stats);
                final barangaysWithMembers = stats.where((s) => s.members > 0).length;
                final membersPerBarangay = barangaysWithMembers == 0 ? 0.0 : total.members / barangaysWithMembers;

                return Column(
                  children: [
                    // Overview averages (always across all LGUs)
                    Row(
                      children: [
                        Expanded(child: _metricBox('Avg. Members per Barangay', _dec1.format(membersPerBarangay), Icons.location_city, cardBg: cardBg, borderCol: borderCol, textCol: textCol, subtextCol: subtextCol, isDark: isDark, primaryCol: primaryCol)),
                        const SizedBox(width: 14),
                        Expanded(child: _metricBox('Avg. Voters per Member', _dec2.format(total.votersPerMember), Icons.how_to_vote, cardBg: cardBg, borderCol: borderCol, textCol: textCol, subtextCol: subtextCol, isDark: isDark, primaryCol: primaryCol)),
                        const SizedBox(width: 14),
                        Expanded(child: _metricBox('Avg. Voters per Household', _dec2.format(total.votersPerHousehold), Icons.home_work, cardBg: cardBg, borderCol: borderCol, textCol: textCol, subtextCol: subtextCol, isDark: isDark, primaryCol: primaryCol)),
                        const SizedBox(width: 14),
                        Expanded(child: _metricBox('Avg. Members per Household', _dec2.format(total.membersPerHousehold), Icons.family_restroom, cardBg: cardBg, borderCol: borderCol, textCol: textCol, subtextCol: subtextCol, isDark: isDark, primaryCol: primaryCol)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _breakdownTable(stats, cardBg: cardBg, borderCol: borderCol, textCol: textCol, subtextCol: subtextCol, isDark: isDark, primaryCol: primaryCol),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static final _int = NumberFormat('#,##0');
  static final _dec1 = NumberFormat('#,##0.0');
  static final _dec2 = NumberFormat('#,##0.00');

  static BarangayStat _sum(Iterable<BarangayStat> rows) =>
      rows.fold(const BarangayStat(lgu: '', barangay: 'TOTAL'), (a, b) => a + b);

  /// Sort value of each sortable column, by column index.
  static final List<Comparable Function(BarangayStat)> _sortKeys = [
    (s) => s.lgu,
    (s) => s.barangay,
    (s) => s.households,
    (s) => s.members,
    (s) => s.voters,
    (s) => s.votersPerMember,
    (s) => s.votersPerHousehold,
    (s) => s.membersPerHousehold,
  ];

  Widget _breakdownTable(List<BarangayStat> stats, {
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtextCol,
    required bool isDark,
    required Color primaryCol,
  }) {
    final lgus = stats.map((s) => s.lgu).where((l) => l.isNotEmpty).toSet().toList()..sort();
    final selected = ref.watch(reportLguFilterProvider);
    final lgu = lgus.contains(selected) ? selected : 'All';

    final rows = lgu == 'All' ? [...stats] : stats.where((s) => s.lgu == lgu).toList();
    if (_sortColumn != null) {
      final key = _sortKeys[_sortColumn!];
      rows.sort((a, b) => _sortAscending ? key(a).compareTo(key(b)) : key(b).compareTo(key(a)));
    }
    final total = _sum(rows);
    final barangaysWithMembers = rows.where((s) => s.members > 0).length;
    final membersPerBarangay = barangaysWithMembers == 0 ? 0.0 : total.members / barangaysWithMembers;

    // One body face (Inter 13, tabular digits so numbers line up) and the shared table header.
    const tabular = [FontFeature.tabularFigures()];
    final bodyStyle = TropaText.body(textCol).copyWith(fontFeatures: tabular);
    final totalStyle = TropaText.bodyStrong(textCol).copyWith(fontWeight: FontWeight.w700, fontFeatures: tabular);
    final headStyle = TropaText.tableHeader(subtextCol);

    void onSort(int i, bool asc) => setState(() {
          _sortColumn = i;
          _sortAscending = asc;
        });

    DataColumn col(String label, {bool numeric = true}) => DataColumn(
          label: Text(label.toUpperCase(), style: headStyle),
          numeric: numeric,
          onSort: onSort,
        );

    List<DataCell> cells(BarangayStat s, TextStyle style) => [
          DataCell(Text(s.lgu, style: style)),
          DataCell(Text(s.barangay, style: style)),
          DataCell(Text(_int.format(s.households), style: style)),
          DataCell(Text(_int.format(s.members), style: style)),
          DataCell(Text(_int.format(s.voters), style: style)),
          DataCell(Text(_dec2.format(s.votersPerMember), style: style)),
          DataCell(Text(_dec2.format(s.votersPerHousehold), style: style)),
          DataCell(Text(_dec2.format(s.membersPerHousehold), style: style)),
        ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barangay Breakdown', style: TropaText.sectionTitle(textCol)),
                    Text(
                      '${_int.format(rows.length)} barangays · avg. ${_dec1.format(membersPerBarangay)} members per barangay',
                      style: TropaText.meta(subtextCol),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(lgu),
                  initialValue: lgu,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
                  dropdownColor: isDark ? TropaColors.darkSurface8dp : Colors.white,
                  style: TropaStyles.fieldText(context),
                  decoration: TropaStyles.filterField(context),
                  items: [
                    DropdownMenuItem(value: 'All', child: Text('All LGUs', style: TropaText.body(textCol))),
                    for (final l in lgus)
                      DropdownMenuItem(value: l, child: Text(l, style: TropaText.body(textCol), overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => ref.read(reportLguFilterProvider.notifier).state = v ?? 'All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No barangays found.', style: TropaText.body(subtextCol))),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: _sortColumn,
                    sortAscending: _sortAscending,
                    headingRowHeight: 40,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 40,
                    columns: [
                      col('LGU', numeric: false),
                      col('Barangay', numeric: false),
                      col('Households'),
                      col('Members'),
                      col('Voters'),
                      col('Voters / Member'),
                      col('Voters / Household'),
                      col('Members / Household'),
                    ],
                    rows: [
                      for (final s in rows)
                        DataRow(cells: cells(s, bodyStyle)),
                      DataRow(
                        color: WidgetStatePropertyAll(primaryCol.withValues(alpha: 0.06)),
                        cells: cells(
                          BarangayStat(
                            lgu: lgu == 'All' ? 'ALL LGUs' : lgu,
                            barangay: 'TOTAL',
                            households: total.households,
                            members: total.members,
                            voters: total.voters,
                          ),
                          totalStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, IconData icon, {
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtextCol,
    required bool isDark,
    required Color primaryCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryCol, size: 20),
          const SizedBox(height: 10),
          Text(value, style: TropaText.kpi(textCol)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TropaText.groupLabel(subtextCol)),
        ],
      ),
    );
  }
}
