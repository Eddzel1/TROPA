import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voter_provider.dart';
import '../../widgets/form_fields.dart';
import 'settings_common.dart';

/// Location Management: barangays (the `locations` table) and their puroks.
class LocationsTab extends ConsumerStatefulWidget {
  const LocationsTab({super.key});

  @override
  ConsumerState<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends ConsumerState<LocationsTab> {
  String _query = '';
  String? _selectedId;

  Future<void> _editLocation({Location? location}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LocationFormDialog(location: location),
    );
    if (saved == true && mounted) {
      showSettingsMessage(context, location == null ? 'Barangay added.' : 'Barangay updated.');
    }
  }

  Future<void> _deleteLocation(Location location) async {
    if (location.inUse) {
      showSettingsMessage(
        context,
        'Cannot delete ${location.barangay}: ${location.householdCount} households and '
        '${location.memberCount} members are registered under it.',
        error: true,
      );
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Delete ${location.barangay}?',
      message: 'This also deletes its ${location.purokCount} puroks and every officer assigned to it.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(supabaseServiceProvider).deleteLocation(location);
      if (!mounted) return;
      setState(() => _selectedId = null);
      showSettingsMessage(context, '${location.barangay} deleted.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final locationsAsync = ref.watch(adminLocationsProvider);

    return locationsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Could not load locations: $e', style: p.body),
      data: (locations) {
        final filtered = locations
            .where((l) => _query.isEmpty || '${l.lgu} ${l.barangay}'.toLowerCase().contains(_query))
            .toList();
        final selected = locations.where((l) => l.id == _selectedId).firstOrNull;
        final lguCount = locations.map((l) => l.lgu).toSet().length;
        final purokCount = locations.fold<int>(0, (sum, l) => sum + l.purokCount);

        final list = SettingsCard(
          title: 'Territorial Jurisdiction',
          subtitle: '$lguCount LGU${lguCount == 1 ? '' : 's'} • ${locations.length} barangays • $purokCount puroks',
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.onPrimary),
              icon: const Icon(Icons.add_location_alt, size: 16),
              label: const Text('Add Barangay'),
              onPressed: () => _editLocation(),
            ),
          ],
          child: Column(
            children: [
              TextField(
                style: TropaStyles.fieldText(context),
                decoration: TropaStyles.filterField(context, hint: 'Search barangay or LGU...', search: true),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No barangays found.', style: p.body))
              else
                for (final l in filtered)
                  ListTile(
                    dense: true,
                    selected: l.id == _selectedId,
                    selectedTileColor: p.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: Icon(
                      l.latitude != null ? Icons.location_on : Icons.location_off,
                      size: 18,
                      color: l.latitude != null ? p.primary : p.subtext,
                    ),
                    title: Text(l.barangay, style: p.bodyStrong),
                    subtitle: Text(l.lgu, style: p.meta),
                    trailing: Text('${l.householdCount} HH • ${l.memberCount} mbr • ${l.purokCount} prk', style: p.meta),
                    onTap: () => setState(() => _selectedId = l.id),
                  ),
            ],
          ),
        );

        final detail = selected == null
            ? Container(
                padding: const EdgeInsets.all(40),
                decoration: p.card,
                child: Center(child: Text('Select a barangay to manage its puroks.', style: p.body)),
              )
            : _LocationDetail(
                location: selected,
                onEdit: () => _editLocation(location: selected),
                onDelete: () => _deleteLocation(selected),
              );

        return LayoutBuilder(
          builder: (context, c) => c.maxWidth < 900
              ? Column(children: [list, const SizedBox(height: 16), detail])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: list),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: detail),
                  ],
                ),
        );
      },
    );
  }
}

class _LocationDetail extends ConsumerWidget {
  final Location location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationDetail({required this.location, required this.onEdit, required this.onDelete});

  Future<void> _addPurok(BuildContext context, WidgetRef ref) async {
    final name = await promptText(context, title: 'Add purok to ${location.barangay}', label: 'Purok name', confirmLabel: 'Add');
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      await ref.read(supabaseServiceProvider).createPurok(location.id, name);
    } catch (e) {
      if (context.mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  Future<void> _renamePurok(BuildContext context, WidgetRef ref, ({String id, String name}) purok) async {
    final name = await promptText(context, title: 'Rename purok', label: 'Purok name', initial: purok.name);
    if (name == null || name.isEmpty || name == purok.name || !context.mounted) return;
    try {
      await ref.read(supabaseServiceProvider).renamePurok(location.id, purok.id, name);
    } catch (e) {
      if (context.mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  Future<void> _deletePurok(BuildContext context, WidgetRef ref, ({String id, String name}) purok) async {
    final ok = await confirmAction(
      context,
      title: 'Delete ${purok.name}?',
      message: 'Officers assigned to this purok are removed as well.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(supabaseServiceProvider).deletePurok(purok.id, purok.name);
    } catch (e) {
      if (context.mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);
    final puroksAsync = ref.watch(puroksProvider(location.id));
    final coords = location.latitude != null && location.longitude != null
        ? '${location.latitude!.toStringAsFixed(5)}, ${location.longitude!.toStringAsFixed(5)}'
        : 'No center coordinates';

    return SettingsCard(
      title: '${location.barangay}, ${location.lgu}',
      subtitle: coords,
      actions: [
        OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit')),
        OutlinedButton.icon(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(foregroundColor: p.error),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SettingsChip('${location.householdCount} households'),
              SettingsChip('${location.memberCount} members'),
              SettingsChip('${location.purokCount} puroks'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Puroks', style: p.title)),
              TextButton.icon(
                onPressed: () => _addPurok(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Purok'),
              ),
            ],
          ),
          Divider(height: 1, color: p.border),
          puroksAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Could not load puroks: $e', style: p.body),
            data: (puroks) => puroks.isEmpty
                ? Padding(padding: const EdgeInsets.all(16), child: Text('No puroks yet.', style: p.caption))
                : Column(
                    children: [
                      for (final purok in puroks)
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: Icon(Icons.holiday_village_outlined, size: 18, color: p.subtext),
                          title: Text(purok.name, style: p.body),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Rename',
                                icon: Icon(Icons.edit_outlined, size: 18, color: p.subtext),
                                onPressed: () => _renamePurok(context, ref, purok),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: Icon(Icons.delete_outline, size: 18, color: p.error),
                                onPressed: () => _deletePurok(context, ref, purok),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationFormDialog extends ConsumerStatefulWidget {
  final Location? location;
  const _LocationFormDialog({this.location});

  @override
  ConsumerState<_LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends ConsumerState<_LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _lgu = TextEditingController(text: widget.location?.lgu ?? 'VALENCIA CITY');
  late final _barangay = TextEditingController(text: widget.location?.barangay ?? '');
  late final _lat = TextEditingController(text: widget.location?.latitude?.toString() ?? '');
  late final _lng = TextEditingController(text: widget.location?.longitude?.toString() ?? '');
  bool _saving = false;

  /// Names can't change while households/members reference them by text.
  bool get _namesLocked => widget.location?.inUse ?? false;

  @override
  void dispose() {
    _lgu.dispose();
    _barangay.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String? _coordValidator(String? v, double min, double max) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final d = double.tryParse(t);
    if (d == null || d < min || d > max) return 'Between $min and $max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if ((lat == null) != (lng == null)) {
      showSettingsMessage(context, 'Enter both latitude and longitude, or neither.', error: true);
      return;
    }
    setState(() => _saving = true);
    final service = ref.read(supabaseServiceProvider);
    try {
      if (widget.location == null) {
        await service.createLocation(lgu: _lgu.text, barangay: _barangay.text, latitude: lat, longitude: lng);
      } else {
        await service.updateLocation(widget.location!, lgu: _lgu.text, barangay: _barangay.text, latitude: lat, longitude: lng);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    return AlertDialog(
      title: Text(widget.location == null ? 'Add Barangay' : 'Edit ${widget.location!.barangay}'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledField(
                label: 'LGU (city / municipality)',
                child: TextFormField(
                  style: TropaStyles.fieldText(context),
                  controller: _lgu,
                  enabled: !_namesLocked,
                  textCapitalization: TextCapitalization.characters,
                  decoration: TropaStyles.formField(context),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Barangay',
                child: TextFormField(
                  style: TropaStyles.fieldText(context),
                  controller: _barangay,
                  enabled: !_namesLocked,
                  textCapitalization: TextCapitalization.characters,
                  decoration: TropaStyles.formField(context),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
              if (_namesLocked) ...[
                const SizedBox(height: 6),
                Text('The name is locked because households and members are registered under it.', style: p.caption),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: 'Center latitude',
                      child: TextFormField(
                        style: TropaStyles.fieldText(context),
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: TropaStyles.formField(context),
                        validator: (v) => _coordValidator(v, -90, 90),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: 'Center longitude',
                      child: TextFormField(
                        style: TropaStyles.fieldText(context),
                        controller: _lng,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: TropaStyles.formField(context),
                        validator: (v) => _coordValidator(v, -180, 180),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('New households in this barangay are placed near its center on the map.', style: p.caption),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(widget.location == null ? 'Add' : 'Save')),
      ],
    );
  }
}
