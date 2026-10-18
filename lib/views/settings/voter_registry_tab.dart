import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/db.dart';
import '../../data/powersync_schema.dart';
import '../../services/voter_snapshot.dart';
import '../../widgets/voter_snapshot_status.dart';
import '../../core/ph_time.dart';
import 'settings_common.dart';

/// Publishes the offline voter list that devices download for Tropa Finder.
class VoterRegistryTab extends ConsumerStatefulWidget {
  const VoterRegistryTab({super.key});

  @override
  ConsumerState<VoterRegistryTab> createState() => _VoterRegistryTabState();
}

class _VoterRegistryTabState extends ConsumerState<VoterRegistryTab> {
  Map<String, dynamic>? _manifest;
  bool _loadingManifest = true;
  String? _progress;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    final manifest = await fetchVoterSnapshotManifest(Supabase.instance.client);
    if (!mounted) return;
    setState(() {
      _manifest = manifest;
      _loadingManifest = false;
    });
  }

  Future<void> _publish() async {
    final ok = await confirmAction(
      context,
      title: 'Publish voter list',
      message: 'Reads every voter in ${snapshotVoterLgus.join(', ')} from Supabase and publishes a new offline '
          'voter list. Every device downloads it (a few MB) the next time it starts online.',
      confirmLabel: 'Publish',
    );
    if (!ok || !mounted) return;

    setState(() => _progress = 'Starting…');
    try {
      final count = await publishVoterSnapshot(
        Supabase.instance.client,
        onProgress: (message) {
          if (mounted) setState(() => _progress = message);
        },
      );
      if (!mounted) return;
      showSettingsMessage(context, 'Published ${NumberFormat('#,###').format(count)} voters.');
      await _loadManifest();
      // Install it on this device straight away.
      ensureVoterSnapshot(ref.read(localDbProvider), Supabase.instance.client).ignore();
    } catch (e) {
      if (!mounted) return;
      final denied = e is StorageException && (e.statusCode == '403' || e.message.contains('row-level security'));
      showSettingsMessage(
        context,
        denied
            ? 'Only users with the Publish offline data permission can publish the voter list.'
            : 'Publishing failed: ${errorMessage(e)}',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final published = parsePh(_manifest?['version']?.toString());
    final count = _manifest?['count'] as int?;

    return SettingsCard(
      title: 'Offline Voter List',
      subtitle: 'Voters of ${snapshotVoterLgus.join(', ')} are shipped to devices as one compressed file, '
          'so Tropa Finder works offline without using PowerSync data. Publish again after importing new voters.',
      actions: [
        FilledButton.icon(
          onPressed: _progress == null ? _publish : null,
          icon: const Icon(Icons.publish, size: 18),
          label: const Text('Publish voter list'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PUBLISHED', style: p.label),
          const SizedBox(height: 4),
          Text(
            _loadingManifest
                ? 'Checking…'
                : published == null
                    ? 'Nothing published yet (or no connection).'
                    : '${NumberFormat('#,###').format(count ?? 0)} voters · '
                        '${formatPh(DateFormat('MMM d, y h:mm a'), published)}',
            style: p.body,
          ),
          const SizedBox(height: 16),
          Text('THIS DEVICE', style: p.label),
          const SizedBox(height: 4),
          const VoterSnapshotStatusLine(),
          if (_progress != null) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            Text(_progress!, style: p.meta),
          ],
        ],
      ),
    );
  }
}
