import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/desktop_scaffold.dart';
import '../views/login_view.dart';
import '../views/dashboard_view.dart';
import '../views/households_view.dart';
import '../views/members_view.dart';
import '../views/dues_view.dart';
import '../views/reports_view.dart';
import '../views/form_tracking_view.dart';
import '../views/tropa_finder_view.dart';
import '../views/settings_view.dart';
import '../views/audit_logs_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(currentAppUserProvider);
  final permissions = ref.watch(userPermissionsProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (BuildContext context, GoRouterState state) {
      final user = userAsync.value;
      final isAuth = user != null;
      final isLogin = state.matchedLocation == '/login';

      if (!isAuth && !isLogin) {
        return '/login';
      }
      if (isAuth && isLogin) {
        return '/dashboard';
      }

      // Role-Based Access Control (RBAC) Guard
      bool can(String perm) =>
          permissions.contains('all') || permissions.contains(perm);

      final path = state.matchedLocation;
      if (path.startsWith('/dashboard') && !can('view_dashboard')) {
        return '/login';
      }
      if (path.startsWith('/households') &&
          !(can('view_households') || can('manage_households'))) {
        return '/dashboard';
      }
      if (path.startsWith('/members') &&
          !(can('view_members') || can('manage_members'))) {
        return '/dashboard';
      }
      if (path.startsWith('/dues') && !can('dues_collection')) {
        return '/dashboard';
      }
      if (path.startsWith('/reports') && !can('view_reports')) {
        return '/dashboard';
      }
      if (path.startsWith('/form-tracking') && !can('user_management')) {
        return '/dashboard';
      }
      if (path.startsWith('/settings') && !can('user_management')) {
        return '/dashboard';
      }
      if (path.startsWith('/logs') && !can('user_management')) {
        return '/dashboard';
      }
      if (path.startsWith('/tropa-finder') && !can('tropa_finder')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      ShellRoute(
        builder: (context, state, child) => DesktopScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const DashboardView()),
          ),
          GoRoute(
            path: '/households',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HouseholdsView()),
          ),
          GoRoute(
            path: '/members',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const MembersView()),
          ),
          GoRoute(
            path: '/dues',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const DuesCollectionView()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const ReportsAnalyticsView()),
          ),
          GoRoute(
            path: '/form-tracking',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const FormTrackingView()),
          ),
          GoRoute(
            path: '/tropa-finder',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const TropaFinderView()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const SettingsAdminView()),
          ),
          GoRoute(
            path: '/logs',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const ActivityLogsView()),
          ),
        ],
      ),
    ],
  );
});
