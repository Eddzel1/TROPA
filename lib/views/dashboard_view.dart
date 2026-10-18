import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../providers/dashboard_provider.dart';
import '../providers/household_provider.dart';
import '../widgets/tropa_map_widget.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final coordinatesAsync = ref.watch(householdCoordinatesProvider);
    final numFormat = NumberFormat('#,###');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Toolbar & Context
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TROPA OPERATING CLUSTER',
                          style: TropaText.groupLabel(primaryCol),
                        ),
                        const SizedBox(width: 6),
                        Text('/', style: TextStyle(color: subtextCol)),
                        const SizedBox(width: 6),
                        Text(
                          'Executive Territorial Ledger',
                          style: TropaText.caption(subtextCol),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dashboard',
                          style: TropaText.pageTitle(textCol),
                        ),
                      ],
                    ),
                  ],
                ),

              ],
            ),

            const SizedBox(height: 24),

            // KPI Cards Cluster
            metricsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TropaColors.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Failed to load live metrics: $err'),
              ),
              data: (data) {
                int toInt(dynamic val) {
                  if (val is num) return val.toInt();
                  if (val != null) {
                    try {
                      final c = (val as dynamic).count;
                      if (c is num) return c.toInt();
                    } catch (_) {}
                    return int.tryParse(val.toString()) ?? 0;
                  }
                  return 0;
                }

                final totalHouseholds = toInt(data['totalHouseholds']);
                final registeredMembers = toInt(data['registeredMembers']);
                final totalVoters = toInt(data['totalVoters']);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: w > 900 ? 3 : (w >= 480 ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 150,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _kpiCard(
                          title: 'TOTAL HOUSEHOLDS',
                          value: numFormat.format(totalHouseholds),
                          unit: 'hh',
                          icon: Icons.cottage,
                          accentColor: primaryCol,
                          subtext: 'Purok verified records',
                          cardBg: cardBg,
                          borderCol: borderCol,
                          textCol: textCol,
                          subtextCol: subtextCol,
                          isDark: isDark,
                        ),
                        _kpiCard(
                          title: 'REGISTERED MEMBERS',
                          value: numFormat.format(registeredMembers),
                          unit: 'indiv',
                          icon: Icons.groups,
                          accentColor: TropaColors.secondaryOf(context),
                          subtext: '51.4% female / 48.6% male',
                          cardBg: cardBg,
                          borderCol: borderCol,
                          textCol: textCol,
                          subtextCol: subtextCol,
                          isDark: isDark,
                        ),
                        _kpiCard(
                          title: 'TOTAL VOTERS',
                          value: numFormat.format(totalVoters),
                          unit: 'voters',
                          icon: Icons.how_to_vote,
                          accentColor: TropaColors.tertiary,
                          subtext: '${registeredMembers > 0 ? ((totalVoters / registeredMembers) * 100).toStringAsFixed(1) : "0.0"}% of registered members',
                          cardBg: cardBg,
                          borderCol: borderCol,
                          textCol: textCol,
                          subtextCol: subtextCol,
                          isDark: isDark,
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            // Geolocation Map Section
            Text(
              'Territorial Member Geolocation (Valencia City, Bukidnon)',
              style: TropaText.dialogTitle(textCol),
            ),
            Text(
              'Visual GPS pin distribution across Banlag, Poblacion, Lilingayon and Barobo',
              style: TropaText.meta(subtextCol),
            ),
            const SizedBox(height: 14),

            Container(
              height: 480,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              clipBehavior: Clip.antiAlias,
              child: coordinatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load map points: $e', style: TextStyle(color: textCol))),
                data: (households) => TropaMapWidget(households: households),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required String subtext,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtextCol,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TropaText.groupLabel(subtextCol)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TropaText.kpi(textCol),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TropaText.fieldLabel(subtextCol).copyWith(fontSize: 12),
                ),
              ],
            ],
          ),
          Text(
            subtext,
            style: TropaText.caption(subtextCol),
          ),
        ],
      ),
    );
  }
}
