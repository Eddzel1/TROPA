import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/db.dart';
import '../../services/device_seed.dart';
import '../../core/ph_time.dart';
import 'settings_common.dart';

/// Starter database for new devices: publish (admins) and download on demand.
class DeviceSeedCard extends ConsumerStatefulWidget {
  const DeviceSeedCard({super.key});

  @override
  ConsumerState<DeviceSeedCard> createState() => _DeviceSeedCardState();
}

class _DeviceSeedCardState extends ConsumerState<DeviceSeedCard> {
  Map<String, dynamic>? _manifest;
  List<String> _localBuckets = const [];
  bool _loading = true;
  String? _publishProgress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final manifest = await fetchDeviceSeedManifest(Supabase.instance.client);
    final rows = await ref.read(localDbProvider).getAll("SELECT name FROM ps_buckets WHERE name <> '\$local' ORDER BY name");
    if (!mounted) return;
    setState(() {
      _manifest = manifest;
      _localBuckets = [for (final r in rows) r['name'] as String];
      _loading = false;
    });
  }

  Future<void> _publish() async {
    final ok = await confirmAction(
      context,
      title: 'Publish starter database',
      message: 'Copies the data on this device (members, households and everything else that syncs) and '
          'publishes it for new devices. This device must be online and fully synced.',
      confirmLabel: 'Publish',
    );
    if (!ok || !mounted) return;

    setState(() => _publishProgress = 'Starting…');
    try {
      final size = await publishDeviceSeed(
        ref.read(localDbProvider),
        Supabase.instance.client,
        onProgress: (message) {
          if (mounted) setState(() => _publishProgress = message);
        },
      );
      if (!mounted) return;
      showSettingsMessage(context, 'Published the starter database (${(size / (1024 * 1024)).toStringAsFixed(0)} MB).');
      await _load();
    } catch (e) {
      if (!mounted) return;
      final denied = e is StorageException && (e.statusCode == '403' || e.message.contains('row-level security'));
      showSettingsMessage(
        context,
        denied ? 'Only users with the admin role can publish the starter database.' : errorMessage(e),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _publishProgress = null);
    }
  }

  Future<void> _download() async {
    final ok = await confirmAction(
      context,
      title: 'Download starter database',
      message: 'Replaces the data on this device with the published starter database, then catches up '
          'with recent changes. The app reloads when it finishes.',
      confirmLabel: 'Download',
    );
    if (!ok || !mounted) return;
    try {
      // On success the app rebuilds on the new database and this card is replaced.
      await installDeviceSeed(force: true);
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final pending = ref.watch(pendingUploadsProvider).value ?? 0;
    final published = parsePh(_manifest?['version']?.toString());
    final bytes = (_manifest?['bytes'] as num?)?.toInt();
    final publishedBuckets = (_manifest?['buckets'] as List?)?.cast<String>() ?? const [];
    final stale = published != null &&
        _localBuckets.isNotEmpty &&
        publishedBuckets.join(',') != _localBuckets.join(',');
    final age = published == null ? null : phNow().difference(published);
    final ageText = age == null
        ? ''
        : age.inDays >= 1
            ? ' · ${age.inDays} day${age.inDays == 1 ? '' : 's'} old'
            : ' · ${age.inHours} hour${age.inHours == 1 ? '' : 's'} old';
    final busy = _publishProgress != null;

    return ValueListenableBuilder<String?>(
      valueListenable: deviceSeedProgress,
      builder: (context, installProgress, _) => SettingsCard(
        title: 'Starter Database',
        subtitle: 'New devices download this file on their first sign-in instead of pulling every member and '
            'household through PowerSync, then only sync the changes since it was published. '
            'Publish again weekly, after big bulk edits, and always after changing the PowerSync sync rules.',
        actions: [
          OutlinedButton.icon(
            onPressed: !deviceSeedSupported || busy || installProgress != null || pending > 0 || published == null
                ? null
                : _download,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download starter database'),
          ),
          FilledButton.icon(
            onPressed: !deviceSeedSupported || busy || installProgress != null ? null : _publish,
            icon: const Icon(Icons.publish, size: 18),
            label: const Text('Publish starter database'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PUBLISHED', style: p.label),
            const SizedBox(height: 4),
            Text(
              _loading
                  ? 'Checking…'
                  : published == null
                      ? 'Nothing published yet (or no connection). New devices do a full sync.'
                      : '${formatPh(DateFormat('MMM d, y h:mm a'), published)}$ageText'
                          '${bytes == null ? '' : ' · ${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB download'}',
              style: p.body,
            ),
            if (stale) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: p.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sync rules changed since this was published, so new devices would download everything again. '
                      'Publish again.',
                      style: p.meta.copyWith(color: p.warning),
                    ),
                  ),
                ],
              ),
            ],
            if (!deviceSeedSupported) ...[
              const SizedBox(height: 8),
              Text('Available in the desktop app only.', style: p.meta),
            ] else if (pending > 0) ...[
              const SizedBox(height: 8),
              Text('Download is disabled while $pending change${pending == 1 ? '' : 's'} on this device wait to upload.',
                  style: p.meta),
            ],
            if (busy || installProgress != null) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text(_publishProgress ?? installProgress!, style: p.meta),
            ],
          ],
        ),
      ),
    );
  }
}
