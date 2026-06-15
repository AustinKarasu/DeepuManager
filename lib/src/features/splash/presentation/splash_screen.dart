import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bootstrap/app_bootstrap.dart';
import '../../../core/security/session_service.dart';
import '../../../core/widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 82),
            const SizedBox(height: 18),
            Text(
              'Deepu Manager',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 130,
              child: LinearProgressIndicator(
                color: scheme.onPrimary,
                backgroundColor: scheme.onPrimary.withValues(alpha: 0.22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _go() async {
    await AppBootstrap.init().timeout(
      const Duration(milliseconds: 700),
      onTimeout: () {},
    );
    final loggedIn = await SessionService.instance.hasValidSession().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => false,
    );
    if (!mounted) return;
    context.go(loggedIn ? '/dashboard' : '/login');
  }
}
