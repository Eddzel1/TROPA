import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../providers/activity_log_provider.dart';
import '../core/ph_time.dart';

class ActivityLogsView extends ConsumerWidget {
  const ActivityLogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsAsyncProvider);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? TropaColors.darkSurface1dp : Colors.white;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    final payloadBg = isDark ? TropaColors.darkSurface0dp : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
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
                    Text('Audit Logs & Mutation Inspector', style: TropaText.pageTitle(textCol)),
                    Text('Immutable trail of all database mutations, uploads, and session authentications', style: TropaText.meta(subtextCol)),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Poll Latest Logs',
                  onPressed: () => ref.refresh(activityLogsAsyncProvider),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading audit log: $err', style: TextStyle(color: textCol))),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 48, color: TropaColors.darkOutline),
                          const SizedBox(height: 12),
                          Text('No mutation logs recorded yet', style: TropaText.sectionTitle(textCol)),
                          const SizedBox(height: 4),
                          Text('Database operations (create, update, delete) will populate here in real-time.', style: TropaText.meta(subtextCol)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderCol),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                        itemBuilder: (context, index) {
                          final l = logs[index];
                          final isDelete = l.action.contains('DELETE');
                          final isCreate = l.action.contains('CREATE') || l.action.contains('ADD');
                          final isUpdate = l.action.contains('UPDATE') || l.action.contains('FLAG');

                          final badgeColor = isDelete
                              ? (isDark ? TropaColors.errorDark : TropaColors.errorLight)
                              : (isCreate
                                  ? TropaColors.secondaryStrongOf(context)
                                  : TropaColors.primaryOf(context));

                          return ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: TropaBadge(l.action, color: badgeColor),
                            title: Row(
                              children: [
                                Text(l.entityType, style: TropaText.bodyStrong(textCol)),
                                const SizedBox(width: 8),
                                if (l.entityId != null)
                                  Text(
                                    '[ID: ${l.entityId!.substring(0, l.entityId!.length > 8 ? 8 : l.entityId!.length)}...]',
                                    style: TropaText.meta(subtextCol),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              'By: ${l.userName} • ${formatPh(dateFormat, l.createdAt)}',
                              style: TropaText.caption(subtextCol),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: payloadBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderCol),
                                ),
                                child: Text(
                                  l.details != null
                                      ? const JsonEncoder.withIndent('  ').convert(l.details)
                                      : 'No additional payload details provided.',
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: TropaColors.primaryOf(context)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
