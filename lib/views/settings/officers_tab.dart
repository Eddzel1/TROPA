import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voter_provider.dart';
import '../../widgets/officer_form_dialog.dart';
import 'settings_common.dart';

/// Organization Structure: barangay federation officers and purok officers of one barangay.
class OfficersTab extends ConsumerStatefulWidget {
  const OfficersTab({super.key});

  @override
  ConsumerState<OfficersTab> createState() => _OfficersTabState();
}

class _OfficersTabState extends ConsumerState<OfficersTab> {
  String? _locationId;

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final locations = ref.watch(adminLocationsProvider).valueOrNull ?? const <Location>[];
    final location = locations.where((l) => l.id == _locationId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: p.card,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Organization Structure', style: p.title),
                  Text('Two levels: the barangay federation and each purok', style: p.caption),
                ],
              ),
              DropdownMenu<String>(
                key: ValueKey(locations.length),
                // Leaves room for page and card padding on phones.
                width: (context.screenWidth - 112).clamp(200.0, 340.0),
                enableFilter: true,
                requestFocusOnTap: true,
                initialSelection: _locationId,
                hintText: 'Select barangay',
                leadingIcon: const Icon(Icons.location_city, size: 18),
                textStyle: TropaStyles.fieldText(context),
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  hintStyle: TropaText.body(p.subtext.withValues(alpha: 0.75)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: p.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: p.border)),
                ),
                dropdownMenuEntries: [
                  for (final l in locations)
                    DropdownMenuEntry(
                      value: l.id,
                      label: '${l.barangay} — ${l.lgu}',
                      style: MenuItemButton.styleFrom(textStyle: TropaStyles.fieldText(context)),
                    ),
                ],
                onSelected: (id) => setState(() => _locationId = id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (location == null)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: p.card,
            child: Center(child: Text('Select a barangay to view and assign its officers.', style: p.body)),
          )
        else
          _BarangayOfficers(location: location),
      ],
    );
  }
}

class _BarangayOfficers extends ConsumerWidget {
  final Location location;
  const _BarangayOfficers({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);
    final officersAsync = ref.watch(officersProvider(location.id));
    final puroksAsync = ref.watch(puroksProvider(location.id));

    return officersAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Could not load officers: $e', style: p.body),
      data: (officers) {
        final federation = officers.where((o) => o.level == Officer.levelBarangay).toList();
        final puroks = puroksAsync.valueOrNull ?? const <({String id, String name})>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsCard(
              title: '${location.barangay} Federation Officers',
              subtitle: 'Barangay-level officers representing every purok in ${location.barangay}',
              child: _OfficerSlate(location: location, officers: federation),
            ),
            const SizedBox(height: 16),
            SettingsCard(
              title: 'Purok Officers',
              subtitle: puroks.isEmpty
                  ? 'Add puroks in the Locations & Barangays tab first'
                  : '${puroks.length} puroks in ${location.barangay}',
              child: puroksAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        for (final purok in puroks)
                          _PurokOfficers(
                            location: location,
                            purok: purok,
                            officers: officers.where((o) => o.level == Officer.levelPurok && o.purokId == purok.id).toList(),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PurokOfficers extends StatelessWidget {
  final Location location;
  final ({String id, String name}) purok;
  final List<Officer> officers;

  const _PurokOfficers({required this.location, required this.purok, required this.officers});

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final filled = OfficerPositions.unique.where((pos) => officers.any((o) => o.position == pos)).length;
    final board = officers.where((o) => o.position == OfficerPositions.boardMember).length;
    final president = officers.where((o) => o.position == OfficerPositions.president).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border.all(color: p.border), borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('purok-${purok.id}'),
          leading: Icon(Icons.holiday_village_outlined, size: 20, color: p.primary),
          title: Text(purok.name, style: p.bodyStrong),
          subtitle: Text(
            '$filled/${OfficerPositions.unique.length} positions filled • $board board members'
            '${president != null ? ' • President: ${president.memberName}' : ''}',
            style: p.meta,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [_OfficerSlate(location: location, purok: purok, officers: officers)],
        ),
      ),
    );
  }
}

/// One slot per unique position plus the Board Members list, for one level (federation or purok).
class _OfficerSlate extends ConsumerWidget {
  final Location location;
  final ({String id, String name})? purok;
  final List<Officer> officers;

  const _OfficerSlate({required this.location, this.purok, required this.officers});

  Future<void> _open(BuildContext context, String position, {Officer? officer}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OfficerFormDialog(
        location: location,
        purok: purok,
        initialPosition: position,
        officer: officer,
        current: officers,
      ),
    );
    if (saved == true && context.mounted) showSettingsMessage(context, '$position saved.');
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Officer officer) async {
    final ok = await confirmAction(
      context,
      title: 'Remove ${officer.memberName}?',
      message: 'They will no longer be listed as ${officer.position}. The member record is not affected.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(supabaseServiceProvider).deleteOfficer(officer);
    } catch (e) {
      if (context.mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);
    final board = officers.where((o) => o.position == OfficerPositions.boardMember).toList();

    Widget holderTile(String position, Officer? o) => Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: o == null ? Colors.transparent : p.chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border, style: o == null ? BorderStyle.solid : BorderStyle.none),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(position.toUpperCase(),
                  style: p.label),
              const SizedBox(height: 6),
              if (o == null) ...[
                Text('Vacant', style: p.body.copyWith(color: p.subtext)),
                const SizedBox(height: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () => _open(context, position),
                  icon: const Icon(Icons.person_add_alt, size: 16),
                  label: Text('Assign', style: p.action),
                ),
              ] else ...[
                Text(o.memberName.isEmpty ? '(member not synced)' : o.memberName,
                    style: p.body.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (o.contactNumber != null && o.contactNumber!.isNotEmpty) Text(o.contactNumber!, style: p.meta),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () => _open(context, o.position, officer: o),
                      child: Text('Change', style: p.action),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, foregroundColor: p.error),
                      onPressed: () => _remove(context, ref, o),
                      child: Text('Remove', style: p.action),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final pos in OfficerPositions.unique)
              holderTile(pos, officers.where((o) => o.position == pos).firstOrNull),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Board Members (${board.length})', style: p.bodyStrong)),
            TextButton.icon(
              onPressed: () => _open(context, OfficerPositions.boardMember),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Board Member'),
            ),
          ],
        ),
        if (board.isEmpty)
          Text('No board members yet.', style: p.caption)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in board)
                InputChip(
                  label: Text(o.memberName.isEmpty ? '(member not synced)' : o.memberName, style: p.body),
                  onPressed: () => _open(context, o.position, officer: o),
                  onDeleted: () => _remove(context, ref, o),
                  deleteButtonTooltipMessage: 'Remove',
                ),
            ],
          ),
      ],
    );
  }
}
