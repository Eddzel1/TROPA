import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';
import 'sync_status_pill.dart';

class DesktopScaffold extends ConsumerWidget {
  final Widget child;

  const DesktopScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only the TROPA theme carries this; it paints the sidebar in brand blue.
    final brand = Theme.of(context).extension<TropaBrand>();
    final sidebarText = brand?.sidebarFg ?? TropaColors.textHigh(context);
    final sidebarMuted = brand?.sidebarFgMuted ?? (isDark ? TropaColors.darkOutline : TropaColors.lightOutline);
    final userAsync = ref.watch(currentAppUserProvider);
    final user = userAsync.value;
    final permissions = ref.watch(userPermissionsProvider);

    bool can(String perm) =>
        permissions.contains('all') || permissions.contains(perm);

    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // ----------------------------------------
          // 1. Sidebar Navigation
          // ----------------------------------------
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: brand?.sidebarBg ?? (isDark ? TropaColors.darkSurfaceLow : TropaColors.lightSurfaceLow),
              border: brand != null
                  ? null
                  : Border(
                      right: BorderSide(
                        color: isDark ? TropaColors.darkOutlineVariant : TropaColors.lightSurfaceHighest,
                        width: 1,
                      ),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo & Status Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
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
                                            : (isDark ? TropaColors.darkSurfaceHigh : TropaColors.lightSurfaceHigh),
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
                      if (can('view_dashboard'))
                        _navItem(
                          context,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          title: 'Dashboard',
                          path: '/dashboard',
                          isActive: currentPath == '/dashboard',
                          brand: brand,
                        ),
                      if (can('view_households'))
                        _navItem(
                          context,
                          icon: Icons.cottage_outlined,
                          activeIcon: Icons.cottage,
                          title: 'Households',
                          path: '/households',
                          isActive: currentPath.startsWith('/households'),
                          brand: brand,
                        ),
                      if (can('view_members'))
                        _navItem(
                          context,
                          icon: Icons.group_outlined,
                          activeIcon: Icons.group,
                          title: 'TROPA Members',
                          path: '/members',
                          isActive: currentPath.startsWith('/members'),
                          brand: brand,
                        ),
                      if (can('dues_collection'))
                        _navItem(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          activeIcon: Icons.account_balance_wallet,
                          title: 'Dues & Ledger',
                          path: '/dues',
                          isActive: currentPath.startsWith('/dues'),
                          brand: brand,
                        ),
                      if (can('view_reports'))
                        _navItem(
                          context,
                          icon: Icons.analytics_outlined,
                          activeIcon: Icons.analytics,
                          title: 'Reports & Analytics',
                          path: '/reports',
                          isActive: currentPath.startsWith('/reports'),
                          brand: brand,
                        ),
                      if (can('user_management'))
                        _navItem(
                          context,
                          icon: Icons.assignment_turned_in_outlined,
                          activeIcon: Icons.assignment_turned_in,
                          title: 'Form Tracking',
                          path: '/form-tracking',
                          isActive: currentPath.startsWith('/form-tracking'),
                          brand: brand,
                        ),
                      if (can('tropa_finder'))
                        _navItem(
                          context,
                          icon: Icons.travel_explore_outlined,
                          activeIcon: Icons.travel_explore,
                          title: 'Tropa Finder',
                          path: '/tropa-finder',
                          isActive: currentPath.startsWith('/tropa-finder'),
                          brand: brand,
                        ),

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

                      if (can('user_management'))
                        _navItem(
                          context,
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          title: 'Settings & Admin',
                          path: '/settings',
                          isActive: currentPath.startsWith('/settings'),
                          brand: brand,
                        ),
                      if (can('user_management'))
                        _navItem(
                          context,
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long,
                          title: 'Audit Logs',
                          path: '/logs',
                          isActive: currentPath.startsWith('/logs'),
                          brand: brand,
                        ),
                    ],
                  ),
                ),

                // Bottom User & Logout Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: brand != null
                          ? brand.sidebarFg.withValues(alpha: 0.12)
                          : (isDark ? TropaColors.darkSurface : TropaColors.lightSurface),
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
                          child: Text(
                            (user?.firstname.isNotEmpty == true
                                ? user!.firstname[0]
                                : 'A').toUpperCase(),
                            style: TextStyle(color: brand?.sidebarActiveFg ?? TropaColors.onPrimaryOf(context), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Executive Admin',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sidebarText),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.role ?? 'Super Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: brand?.sidebarFgMuted ?? TropaColors.primaryOf(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout, size: 18, color: brand?.sidebarFgMuted ?? TropaColors.textMedium(context)),
                          tooltip: 'Sign Out',
                          onPressed: () async {
                            await ref.read(currentAppUserProvider.notifier).signOut();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------
          // 2. Main Page View + Header Bar
          // ----------------------------------------
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? TropaColors.darkBackground.withValues(alpha: 0.95)
                        : TropaColors.lightBackground.withValues(alpha: 0.95),
                    border: Border(
                      bottom: BorderSide(
                        color: TropaColors.borderOf(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
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
                          Text(
                            _pageTitle(currentPath),
                            style: TropaText.bodyStrong(TropaColors.textHigh(context)),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Sync pill
                      SyncStatusPill(isDark: isDark),

                      const SizedBox(width: 12),

                      // Notification icon
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: TropaColors.textMedium(context),
                            ),
                            onPressed: () {},
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: TropaColors.secondaryOf(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Child View Area
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            context.go(path);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? (brand?.sidebarActiveBg ?? TropaColors.primaryOf(context))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive
                      ? (brand?.sidebarActiveFg ?? TropaColors.onPrimaryOf(context))
                      : (brand?.sidebarFgMuted ?? TropaColors.textMedium(context)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? (brand?.sidebarActiveFg ?? TropaColors.onPrimaryOf(context))
                        : (brand?.sidebarFg ?? TropaColors.textHigh(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
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
