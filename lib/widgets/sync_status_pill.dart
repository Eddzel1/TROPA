import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/motion.dart';
import '../data/db.dart';
import '../services/fallback_sync.dart';
import '../core/ph_time.dart';

/// Header pill showing whether this device is synced with the server, and how many changes are queued.
/// Tapping it opens [SyncQueueDialog].
class SyncStatusPill extends ConsumerWidget {
  final bool isDark;

  /// Phone header: just the status dot, with the label moved into the tooltip.
  final bool compact;

  const SyncStatusPill({super.key, required this.isDark, this.compact = false});

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
    final refused = ref.watch(uploadRejectionsProvider).value?.length ?? 0;

    final (color, label, tooltip) = switch (state) {
      // Supabase turned changes down; they come undone on this device, so this stays until dismissed.
      _ when refused > 0 => (
          TropaColors.errorOf(context),
          '$refused change${refused == 1 ? '' : 's'} refused',
          'The server refused $refused change${refused == 1 ? '' : 's'} made on this device, so '
              '${refused == 1 ? 'it was' : 'they were'} undone. Open the sync queue to see why.',
        ),
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

    // Pulses once when the queue empties and the device is up to date.
    final upToDate = state == SyncState.synced && pending == 0 && !uploadFailing && refused == 0;

    return Tooltip(
      message: compact ? '$label\n$tooltip\nTap to view the sync queue.' : '$tooltip\nClick to view the sync queue.',
      child: TropaSuccessPulse(
        done: upToDate,
        child: Material(
          color: TropaColors.chipOf(context),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showTropaDialog<void>(context: context, builder: (_) => const SyncQueueDialog()),
            child: Padding(
              padding: compact ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 8 : 6,
                    height: compact ? 8 : 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TropaText.badge(TropaColors.textMedium(context)),
                    ),
                  ],
                ],
              ),
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
            const _RefusedChanges(),
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

/// Changes Supabase refused, with its reason, above the upload queue. Hidden when there are none.
class _RefusedChanges extends ConsumerWidget {
  const _RefusedChanges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejections = ref.watch(uploadRejectionsProvider).value ?? const <UploadRejection>[];
    if (rejections.isEmpty) return const SizedBox.shrink();
    final error = TropaColors.errorOf(context);
    final db = ref.read(localDbProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
              child: Row(
                children: [
                  Icon(Icons.block, size: 16, color: error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Refused by the server (${rejections.length}) · undone on this device',
                      style: TropaText.bodyStrong(error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => db.execute('DELETE FROM upload_rejections'),
                    child: const Text('Dismiss all'),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
                itemCount: rejections.length,
                separatorBuilder: (_, __) => Divider(height: 12, color: error.withValues(alpha: 0.2)),
                itemBuilder: (context, i) {
                  final r = rejections[i];
                  final what = '${r.op} ${r.table.replaceAll('_', ' ')}'
                      '${r.changeCount > 1 ? ' (with ${r.changeCount - 1} other change${r.changeCount == 2 ? '' : 's'})' : ''}';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(what, style: TropaText.bodyStrong(TropaColors.textHigh(context))),
                            SelectableText(
                              '${r.code.isEmpty ? '' : '${r.code}: '}${r.message}',
                              style: TropaText.meta(error),
                            ),
                            Text(
                              '${r.rowId} · ${formatPh(DateFormat('MMM d, h:mm a'), r.at)}',
                              style: TropaText.caption(TropaColors.textMedium(context)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => db.execute('DELETE FROM upload_rejections WHERE id = ?', [r.id]),
                      ),
                    ],
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
