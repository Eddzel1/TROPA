import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../core/theme_palettes.dart';
import '../core/theme_provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'settings/locations_tab.dart';
import 'settings/officers_tab.dart';
import 'settings/settings_common.dart';
import 'settings/users_tab.dart';
import 'settings/device_seed_card.dart';
import 'settings/dues_rate_tab.dart';
import 'settings/voter_registry_tab.dart';

class SettingsAdminView extends ConsumerWidget {
  const SettingsAdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);
    // Phones pick the section from a dropdown instead of a tab strip.
    final compact = context.isCompactScreen;

    Widget scrollable(Widget child) => SingleChildScrollView(
          padding: compact ? const EdgeInsets.fromLTRB(16, 12, 16, 16) : const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: child,
        );
    bool can(String perm) => ref.watch(canPermissionProvider(perm));

    (IconData, String) tab(IconData icon, String text) => (icon, text);

    // Each tab shows only with its permission; Appearance is a per-device preference open to everyone.
    final tabs = <((IconData, String), Widget)>[
      if (can(AppPermissions.manageUsers)) ...[
        (tab(Icons.manage_accounts, 'Users & Permissions'), scrollable(const UsersTab())),
        (tab(Icons.payments_outlined, 'Dues Rate'), scrollable(const DuesRateTab())),
      ],
      if (can(AppPermissions.manageLocations)) ...[
        (tab(Icons.map_outlined, 'Locations & Barangays'), scrollable(const LocationsTab())),
        (tab(Icons.account_tree_outlined, 'Organization & Officers'), scrollable(const OfficersTab())),
      ],
      if (can(AppPermissions.publishOfflineData))
        (
          tab(Icons.how_to_vote_outlined, 'Offline Data'),
          scrollable(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [DeviceSeedCard(), SizedBox(height: 16), VoterRegistryTab()],
          )),
        ),
      (tab(Icons.palette_outlined, 'Appearance'), scrollable(const _AppearanceTab())),
    ];

    return DefaultTabController(
      // Rebuilt when the tab count changes, e.g. after the user's permissions sync.
      key: ValueKey(tabs.length),
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: compact ? const EdgeInsets.fromLTRB(16, 16, 16, 8) : const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings & Administration', style: TropaText.pageTitle(p.text)),
                  Text('Staff accounts, locations, officers, offline data and appearance',
                      style: TropaText.caption(p.subtext)),
                ],
              ),
            ),
            if (compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _SectionPicker(sections: [for (final t in tabs) t.$1]),
              )
            else
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelColor: p.primary,
                unselectedLabelColor: p.subtext,
                indicatorColor: p.primary,
                dividerColor: p.border,
                labelStyle: TropaText.bodyStrong(p.primary),
                tabs: [
                  for (final (icon, text) in [for (final t in tabs) t.$1])
                    Tab(icon: Icon(icon, size: 18), iconMargin: const EdgeInsets.only(bottom: 2), text: text),
                ],
              ),
            Expanded(
              child: TabBarView(
                // The dropdown is the only way to switch on phones; no accidental swipes.
                physics: compact ? const NeverScrollableScrollPhysics() : null,
                children: [for (final t in tabs) t.$2],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone replacement for the settings tab strip: a dropdown bound to the [DefaultTabController].
class _SectionPicker extends StatelessWidget {
  final List<(IconData, String)> sections;

  const _SectionPicker({required this.sections});

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final p = SettingsPalette.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => DropdownButtonFormField<int>(
        key: ValueKey(controller.index),
        initialValue: controller.index,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, color: p.text),
        dropdownColor: TropaColors.cardOf(context),
        decoration: TropaStyles.filterField(context),
        items: [
          for (final (i, (icon, text)) in sections.indexed)
            DropdownMenuItem(
              value: i,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: p.primary),
                  const SizedBox(width: 10),
                  Flexible(child: Text(text, style: TropaText.bodyStrong(p.text), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
        ],
        onChanged: (i) {
          if (i != null) controller.animateTo(i);
        },
      ),
    );
  }
}

class _AppearanceTab extends ConsumerWidget {
  const _AppearanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);
    final selectedId = ref.watch(appThemeProvider);

    return SettingsCard(
      title: 'Application Appearance & Theme',
      subtitle: 'Saved on this device only.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, brightness) in [('LIGHT', Brightness.light), ('DARK', Brightness.dark)]) ...[
            if (brightness == Brightness.dark) const SizedBox(height: 20),
            Text(label, style: p.label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final palette in tropaPalettes.where((t) => t.brightness == brightness))
                  _ThemeSwatch(
                    palette: palette,
                    selected: palette.id == selectedId,
                    onTap: () => ref.read(appThemeProvider.notifier).setTheme(palette.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One tile in the theme picker: the palette's primary and background colours, and its name.
class _ThemeSwatch extends StatelessWidget {
  final TropaPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({required this.palette, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.name} theme',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? p.primary : p.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview: a card on the palette's background, with its text, muted text and primary.
              Container(
                height: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Aa', style: TropaText.bodyStrong(palette.text)),
                            Text('Members', style: TropaText.caption(palette.muted)),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle),
                        child: Icon(Icons.check, size: 14, color: palette.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // The palette's colours; hover one for its role and hex code.
              Row(
                children: [
                  for (final (role, color) in [
                    ('Background', palette.background),
                    ('Surface', palette.surface),
                    ('Primary', palette.primary),
                    ('Secondary', palette.secondary),
                    ('Text', palette.text),
                    ('Muted text', palette.muted),
                  ])
                    Expanded(
                      child: Tooltip(
                        message: '$role #${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        child: Container(
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: p.border),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(palette.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: p.bodyStrong),
                  ),
                  if (selected) Icon(Icons.check_circle, size: 16, color: p.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
