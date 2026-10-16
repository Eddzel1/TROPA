import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../core/theme_provider.dart';
import 'settings/locations_tab.dart';
import 'settings/officers_tab.dart';
import 'settings/settings_common.dart';
import 'settings/users_tab.dart';
import 'settings/device_seed_card.dart';
import 'settings/voter_registry_tab.dart';

class SettingsAdminView extends ConsumerWidget {
  const SettingsAdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);

    Widget scrollable(Widget child) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: child,
        );

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings & Administration', style: TropaText.pageTitle(p.text)),
                  Text('Manage staff accounts and permissions, barangays and puroks, and organizational officers',
                      style: TropaText.caption(p.subtext)),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelColor: p.primary,
              unselectedLabelColor: p.subtext,
              indicatorColor: p.primary,
              dividerColor: p.border,
              labelStyle: TropaText.bodyStrong(p.primary),
              tabs: const [
                Tab(icon: Icon(Icons.manage_accounts, size: 18), iconMargin: EdgeInsets.only(bottom: 2), text: 'Users & Permissions'),
                Tab(icon: Icon(Icons.map_outlined, size: 18), iconMargin: EdgeInsets.only(bottom: 2), text: 'Locations & Barangays'),
                Tab(icon: Icon(Icons.account_tree_outlined, size: 18), iconMargin: EdgeInsets.only(bottom: 2), text: 'Organization & Officers'),
                Tab(icon: Icon(Icons.how_to_vote_outlined, size: 18), iconMargin: EdgeInsets.only(bottom: 2), text: 'Offline Data'),
                Tab(icon: Icon(Icons.palette_outlined, size: 18), iconMargin: EdgeInsets.only(bottom: 2), text: 'Appearance'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  scrollable(const UsersTab()),
                  scrollable(const LocationsTab()),
                  scrollable(const OfficersTab()),
                  scrollable(const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [DeviceSeedCard(), SizedBox(height: 16), VoterRegistryTab()],
                  )),
                  scrollable(const _AppearanceTab()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceTab extends ConsumerWidget {
  const _AppearanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SettingsPalette.of(context);
    final appTheme = ref.watch(appThemeProvider);

    return SettingsCard(
      title: 'Application Appearance & Theme',
      child: Row(
        children: [
          Text('Active Theme Mode:', style: p.body),
          const SizedBox(width: 16),
          SegmentedButton<AppTheme>(
            segments: const [
              ButtonSegment(value: AppTheme.dark, label: Text('Dark Slate (Civic)'), icon: Icon(Icons.dark_mode, size: 16)),
              ButtonSegment(value: AppTheme.light, label: Text('Clean Light'), icon: Icon(Icons.light_mode, size: 16)),
              ButtonSegment(value: AppTheme.tropa, label: Text('TROPA'), icon: Icon(Icons.shield, size: 16)),
            ],
            selected: {appTheme},
            onSelectionChanged: (set) => ref.read(appThemeProvider.notifier).setTheme(set.first),
          ),
        ],
      ),
    );
  }
}
