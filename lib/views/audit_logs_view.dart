import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_header.dart';
import '../providers/activity_log_provider.dart';
import '../core/ph_time.dart';

class ActivityLogsView extends ConsumerWidget {
  const ActivityLogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsAsyncProvider);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final payloadBg = TropaColors.subtleOf(context);

    // Phones: the action badge joins the title instead of taking a fixed leading slot.
    final compact = context.isCompactScreen;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TropaPageHeader(
              title: 'Audit Logs & Mutation Inspector',
              subtitle: 'Immutable trail of all database mutations, uploads, and session authentications',
              actions: [
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
                          Icon(Icons.receipt_long_outlined, size: 48, color: TropaColors.textDisabled(context)),
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
                              ? TropaColors.errorOf(context)
                              : (isCreate
                                  ? TropaColors.secondaryStrongOf(context)
                                  : TropaColors.primaryOf(context));

                          return ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 4),
                            leading: compact ? null : TropaBadge(l.action, color: badgeColor),
                            title: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (compact) TropaBadge(l.action, color: badgeColor),
                                Text(l.entityType, style: TropaText.bodyStrong(textCol)),
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
