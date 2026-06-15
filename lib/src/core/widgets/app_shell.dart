import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../security/session_service.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final baseTabs = <({String path, IconData icon, String label})>[
      (path: '/dashboard', icon: Icons.home_outlined, label: 'Home'),
      (path: '/registers', icon: Icons.receipt_long_outlined, label: 'Registers'),
      (path: '/analytics', icon: Icons.analytics_outlined, label: 'Analytics'),
      (path: '/reports', icon: Icons.assignment_outlined, label: 'Reports'),
      (path: '/profile', icon: Icons.person_outline, label: 'Profile'),
    ];
    final user = SessionService.instance.cachedUserSync();
    final tabs = [
      ...baseTabs,
      if (user?['role'] == 'admin')
        (path: '/admin', icon: Icons.admin_panel_settings_outlined, label: 'Admin'),
    ];
    final index = tabs.indexWhere((tab) => location.startsWith(tab.path));
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(tabs[i].path),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
