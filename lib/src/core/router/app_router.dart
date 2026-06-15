import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/request_access_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/register/presentation/register_editor_screen.dart';
import '../../features/register/presentation/register_list_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/profile/presentation/profile_settings_screen.dart';
import '../security/session_service.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await SessionService.instance.hasValidSession();
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/request-access';
      if (!isLoggedIn && !onAuth) return '/login';
      if (isLoggedIn && state.matchedLocation == '/login') return '/dashboard';
      if (state.matchedLocation == '/admin') {
        final user = await SessionService.instance.cachedUser();
        if (user?['role'] != 'admin') return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/request-access',
        builder: (_, __) => const RequestAccessScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/registers', builder: (_, __) => const RegisterListScreen()),
          GoRoute(
            path: '/registers/new',
            builder: (_, __) => const RegisterEditorScreen(),
          ),
          GoRoute(
            path: '/registers/:id',
            builder: (_, state) => RegisterEditorScreen(
              registerId: state.pathParameters['id'],
            ),
          ),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileSettingsScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        ],
      ),
    ],
  );
});
