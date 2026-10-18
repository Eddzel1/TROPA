import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'sync_status_pill.dart';

/// App shell for every signed-in page. Desktop gets the full sidebar, tablets an icon rail, and
/// phones a drawer opened from the header.
class DesktopScaffold extends ConsumerWidget {
  final Widget child;

  const DesktopScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only the TROPA theme carries this; it paints the sidebar in brand blue.
    final brand = Theme.of(context).extension<TropaBrand>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = TropaBreakpoints.isCompact(width);
    final rail = !compact && !TropaBreakpoints.isExpanded(width);

    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      drawer: compact
          ? Drawer(
              width: 280,
              backgroundColor: brand?.sidebarBg ?? TropaColors.cardOf(context),
              shape: const RoundedRectangleBorder(),
              child: SafeArea(child: _Sidebar(currentPath: currentPath, inDrawer: true)),
            )
          : null,
      body: Row(
        children: [
          // ----------------------------------------
          // 1. Sidebar Navigation (rail on tablets, hidden in the drawer on phones)
          // ----------------------------------------
          if (!compact)
            Container(
              width: rail ? 76 : 270,
              decoration: BoxDecoration(
                color: brand?.sidebarBg ?? TropaColors.cardOf(context),
                border: brand != null
                    ? null
                    : Border(
                        right: BorderSide(
                          color: TropaColors.borderOf(context),
                          width: 1,
                        ),
                      ),
              ),
              child: SafeArea(right: false, child: _Sidebar(currentPath: currentPath, rail: rail)),
            ),

          // ----------------------------------------
          // 2. Main Page View + Header Bar
          // ----------------------------------------
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                  decoration: BoxDecoration(
                    color: TropaColors.backgroundOf(context).withValues(alpha: 0.95),
                    border: Border(
                      bottom: BorderSide(
                        color: TropaColors.borderOf(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: compact ? 56 : 64,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 24),
                      child: Row(
                        children: [
                          if (compact)
                            Builder(
                              builder: (context) => IconButton(
                                icon: Icon(Icons.menu, color: TropaColors.textHigh(context)),
                                tooltip: 'Menu',
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),

                          // Breadcrumb (just the page title on phones)
                          Expanded(
                            child: Row(
                              children: [
                                if (!compact) ...[
                                  Icon(
                                    Icons.domain,
                                    size: 16,
                                    color: TropaColors.textDisabled(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TROPA Member',
                                    style: TropaText.body(TropaColors.textMedium(context)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '/',
                                    style: TextStyle(
                                      color: TropaColors.textDisabled(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    _pageTitle(currentPath),
                                    style: TropaText.bodyStrong(TropaColors.textHigh(context)),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Sync pill
                          SyncStatusPill(isDark: isDark, compact: compact),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Child View Area
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle(String path) {
    if (path.startsWith('/dashboard')) return 'Dashboard';
    if (path.startsWith('/households')) return 'Households Directory';
    if (path.startsWith('/members')) return 'TROPA Members Directory';
    if (path.startsWith('/dues')) return 'Dues & Ledger';
    if (path.startsWith('/reports')) return 'Reports & Analytics';
    if (path.startsWith('/form-tracking')) return 'Field Form Intake Tracking';
    if (path.startsWith('/tropa-finder')) return 'Tropa Finder (COMELEC Sync)';
    if (path.startsWith('/settings')) return 'Settings & Administration';
    if (path.startsWith('/logs')) return 'Audit Logs & Mutation Inspector';
    return 'Overview';
  }
}

/// Logo, nav links and the signed-in user card. [rail] shrinks it to icons only (tablets);
/// [inDrawer] closes the phone drawer after a link is tapped.
class _Sidebar extends ConsumerWidget {
  final String currentPath;
  final bool rail;
  final bool inDrawer;

  const _Sidebar({required this.currentPath, this.rail = false, this.inDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = Theme.of(context).extension<TropaBrand>();
    final sidebarText = brand?.sidebarFg ?? TropaColors.textHigh(context);
    final sidebarMuted = brand?.sidebarFgMuted ?? TropaColors.textDisabled(context);
    final userAsync = ref.watch(currentAppUserProvider);
    final user = userAsync.value;
    final permissions = ref.watch(userPermissionsProvider);

    bool can(String perm) => permissions.contains(AppPermissions.systemAdmin) || permissions.contains(perm);

    Widget nav(IconData icon, IconData activeIcon, String title, String path, {bool exact = false}) => _navItem(
          context,
          icon: icon,
          activeIcon: activeIcon,
          title: title,
          path: path,
          isActive: exact ? currentPath == path : currentPath.startsWith(path),
          brand: brand,
        );

    Future<void> signOut() async {
      await ref.read(currentAppUserProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }

    final initial = Text(
      (user?.firstname.isNotEmpty == true ? user!.firstname[0] : 'A').toUpperCase(),
      style: TextStyle(color: brand?.sidebarActiveFg ?? TropaColors.onPrimaryOf(context), fontWeight: FontWeight.bold),
    );
    final logoutIcon = Icon(Icons.logout, size: 18, color: brand?.sidebarFgMuted ?? TropaColors.textMedium(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo & Status Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: rail
              ? Center(
                  child: Image.asset(
                    'assets/images/tropa_logo.png',
                    width: 36,
                    height: 36,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'TROPA logo',
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/tropa_logo.png',
                            width: 36,
                            height: 36,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: 'TROPA logo',
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'TROPA',
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: brand?.sidebarFg,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: brand != null
                                            ? brand.sidebarFg.withValues(alpha: 0.15)
                                            : TropaColors.chipOf(context),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'v2.0',
                                        style: TropaText.badge(brand?.sidebarFg ?? TropaColors.primaryOf(context)),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Tabang Respeto Og Panalipud',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: sidebarMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // Nav Links List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (can('view_dashboard')) nav(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', '/dashboard', exact: true),
              if (can('view_households')) nav(Icons.cottage_outlined, Icons.cottage, 'Households', '/households'),
              if (can('view_members')) nav(Icons.group_outlined, Icons.group, 'TROPA Members', '/members'),
              if (can('dues_collection'))
                nav(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Dues & Ledger', '/dues'),
              if (can('view_reports')) nav(Icons.analytics_outlined, Icons.analytics, 'Reports & Analytics', '/reports'),
              if (can('form_tracking'))
                nav(Icons.assignment_turned_in_outlined, Icons.assignment_turned_in, 'Form Tracking', '/form-tracking'),
              if (can('tropa_finder')) nav(Icons.travel_explore_outlined, Icons.travel_explore, 'Tropa Finder', '/tropa-finder'),
              if (rail)
                Divider(height: 24, color: sidebarMuted.withValues(alpha: 0.3))
              else
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 12),
                  child: Text(
                    'SYSTEM ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: sidebarMuted,
                    ),
                  ),
                ),
              nav(Icons.settings_outlined, Icons.settings, 'Settings & Admin', '/settings'),
              if (can('view_audit_logs')) nav(Icons.receipt_long_outlined, Icons.receipt_long, 'Audit Logs', '/logs'),
            ],
          ),
        ),

        // Bottom User & Logout Card
        if (rail)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Column(
                children: [
                  Tooltip(
                    message: '${user?.fullName ?? ''}\n${AppPermissions.summary(permissions)}',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: brand?.sidebarActiveBg ?? TropaColors.primaryOf(context),
                      child: initial,
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(icon: logoutIcon, tooltip: 'Sign Out', onPressed: signOut),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: brand != null ? brand.sidebarFg.withValues(alpha: 0.12) : TropaColors.cardOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brand != null ? brand.sidebarFg.withValues(alpha: 0.2) : TropaColors.borderOf(context),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: brand?.sidebarActiveBg ?? TropaColors.primaryOf(context),
                    child: initial,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sidebarText),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppPermissions.summary(permissions),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: brand?.sidebarFgMuted ?? TropaColors.primaryOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: logoutIcon, tooltip: 'Sign Out', onPressed: signOut),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String path,
    required bool isActive,
    required TropaBrand? brand,
  }) {
    final iconWidget = Icon(
      isActive ? activeIcon : icon,
      size: 20,
      color: isActive
          ? (brand?.sidebarActiveFg ?? TropaColors.onPrimaryOf(context))
          : (brand?.sidebarFgMuted ?? TropaColors.textMedium(context)),
    );

    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (inDrawer) Navigator.of(context).pop();
            context.go(path);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: rail ? 0 : 14, vertical: rail ? 12 : 10),
            decoration: BoxDecoration(
              color: isActive ? (brand?.sidebarActiveBg ?? TropaColors.primaryOf(context)) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: rail
                ? Center(child: iconWidget)
                : Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? (brand?.sidebarActiveFg ?? TropaColors.onPrimaryOf(context))
                              : (brand?.sidebarFg ?? TropaColors.textHigh(context)),
                        ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return rail ? Tooltip(message: title, preferBelow: false, child: item) : item;
  }
}
