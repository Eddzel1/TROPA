import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../data/db.dart';
import '../services/fallback_sync.dart';
import '../core/ph_time.dart';

/// Header pill showing whether this device is synced with the server, and how many changes are queued.
/// Tapping it opens [SyncQueueDialog].
class SyncStatusPill extends ConsumerWidget {
  final bool isDark;

  const SyncStatusPill({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final pending = ref.watch(pendingUploadsProvider).value ?? 0;
    final status = ref.watch(syncStatusProvider).value;
    final lastSynced = status?.lastSyncedAt;
    final lastSyncedText = lastSynced == null ? 'never' : formatPh(DateFormat('MMM d, h:mm a'), lastSynced);
    final pendingSuffix = pending > 0 ? ' · $pending pending' : '';
    final backupPulledAt = ref.watch(fallbackSyncStateProvider).value.lastPulledAt;
    final backupChecked = backupPulledAt == null ? null : formatPh(DateFormat('h:mm a'), backupPulledAt);
    final uploadFailing = state.isOnline && pending > 0 && status?.uploadError != null;

    final (color, label, tooltip) = switch (state) {
      // Connected but changes are stuck in the queue: the server keeps rejecting the upload.
      _ when uploadFailing => (
          TropaColors.errorLight,
          'Upload failing$pendingSuffix',
          'Connected, but the server rejected the queued changes. They will be retried automatically.',
        ),
      // Connected with changes still queued: they are uploading, not "online and done".
      SyncState.synced || SyncState.syncing when pending > 0 => (
          TropaColors.secondaryOf(context),
          'Syncing$pendingSuffix',
          'Uploading changes to the server.',
        ),
      SyncState.synced => (
          TropaColors.secondaryOf(context),
          'Server Online',
          'Connected to the server and up to date. Last synced $lastSyncedText.',
        ),
      SyncState.syncing => (TropaColors.secondaryOf(context), 'Syncing…', 'Sending and receiving changes.'),
      SyncState.offline => (
          TropaColors.offline,
          'Offline$pendingSuffix',
          'No connection. Changes are saved on this device and upload automatically when you are back '
              'online. Last synced $lastSyncedText.',
        ),
      SyncState.backup => (
          TropaColors.secondaryOf(context),
          'Backup sync$pendingSuffix',
          'The sync service is unavailable, so this device checks the server for other devices\' changes '
              'every 3 minutes${backupChecked == null ? '' : ' (last checked $backupChecked)'}. '
              'Your own changes still upload normally.',
        ),
      SyncState.localOnly => (TropaColors.offline, 'Local only', 'Sync is not configured (POWERSYNC_URL is empty).'),
    };

    return Tooltip(
      message: '$tooltip\nClick to view the sync queue.',
      child: Material(
        color: isDark ? TropaColors.darkSurface2dp : TropaColors.lightSurfaceLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showDialog<void>(context: context, builder: (_) => const SyncQueueDialog()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TropaText.badge(TropaColors.textMedium(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lists the local changes still waiting to upload. The list shrinks live as uploads complete.
class SyncQueueDialog extends ConsumerWidget {
  const SyncQueueDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final entriesAsync = ref.watch(pendingUploadEntriesProvider);
    final status = ref.watch(syncStatusProvider).value;
    final lastSynced = status?.lastSyncedAt;
    final lastSyncedText = lastSynced == null ? 'never' : formatPh(DateFormat('MMM d, h:mm a'), lastSynced);
    final uploadError = status?.uploadError;

    final statusText = switch (state) {
      SyncState.synced => 'Server online',
      SyncState.syncing => 'Syncing…',
      SyncState.offline => 'Offline — changes will upload when the connection returns',
      SyncState.backup => 'Backup sync — the sync service is unavailable; checking the server every 3 minutes',
      SyncState.localOnly => 'Sync is not configured',
    };

    return AlertDialog(
      title: const Text('Sync Queue'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$statusText · Last synced $lastSyncedText',
              style: TropaText.meta(TropaColors.textMedium(context)),
            ),
            if (uploadError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TropaColors.errorLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TropaColors.errorLight.withValues(alpha: 0.3)),
                ),
                child: SelectableText(
                  'Last upload failed: $uploadError',
                  style: TropaText.meta(TropaColors.errorLight),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not read the sync queue: $e')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done_outlined, size: 40, color: TropaColors.secondaryOf(context)),
                          const SizedBox(height: 8),
                          Text(
                            'Nothing waiting to sync.',
                            style: TropaText.body(TropaColors.textMedium(context)),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entries.length} change${entries.length == 1 ? '' : 's'} waiting to upload',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) => _QueueTile(entry: entries[i]),
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
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

class _QueueTile extends StatelessWidget {
  final PendingUpload entry;

  const _QueueTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (opLabel, opColor) = switch (entry.op) {
      'PUT' => ('NEW', TropaColors.secondaryVariant),
      'PATCH' => ('EDIT', TropaColors.primaryOf(context)),
      'DELETE' => ('DELETE', TropaColors.offline),
      _ => (entry.op, TropaColors.textMedium(context)),
    };
    final title = entry.table.replaceAll('_', ' ');
    final details = entry.data.isEmpty ? null : const JsonEncoder.withIndent('  ').convert(entry.data);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: opColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          opLabel,
          style: TropaText.badge(opColor),
        ),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        entry.rowId,
        style: TropaText.meta(TropaColors.textMedium(context)),
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        SelectableText(
          details ?? 'No field data (row is being deleted).',
          style: TropaText.meta(TropaColors.textMedium(context)),
        ),
      ],
    );
  }
}
