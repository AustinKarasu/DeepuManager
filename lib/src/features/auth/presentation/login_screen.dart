import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/security/security_settings_service.dart';
import '../../../core/security/session_service.dart';
import '../../../core/widgets/brand_logo.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  bool _biometricEnabled = false;
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUnlockOptions();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(data: (user) {
        if (user != null) context.go('/dashboard');
      });
    });
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Center(child: BrandLogo(size: 58)),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Log in to manage your inventory',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: auth.isLoading ? null : _login,
                  child: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                if (_biometricEnabled || _pinEnabled) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'UNLOCK SESSION',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_pinEnabled) ...[
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Secure PIN'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      if (_biometricEnabled)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _biometric,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Biometrics'),
                          ),
                        ),
                      if (_biometricEnabled && _pinEnabled) const SizedBox(width: 12),
                      if (_pinEnabled)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _unlockWithPin,
                            icon: const Icon(Icons.pin_outlined),
                            label: const Text('Secure PIN'),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/request-access'),
                  child: const Text('Need access? Request Account'),
                ),
                if (auth.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      auth.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    await ref.read(authControllerProvider.notifier).login(_email.text, _password.text);
  }

  Future<void> _biometric() async {
    if (!await SessionService.instance.hasValidSession()) return;
    final ok = await BiometricService.instance.authenticate();
    if (!mounted || !ok) return;
    await ref.read(authControllerProvider.notifier).unlockCachedSession();
  }

  Future<void> _unlockWithPin() async {
    if (!await SessionService.instance.hasValidSession()) return;
    final ok = await SecuritySettingsService.instance.verifyPin(_pin.text.trim());
    if (!mounted || !ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid secure PIN')),
        );
      }
      return;
    }
    await ref.read(authControllerProvider.notifier).unlockCachedSession();
  }

  Future<void> _loadUnlockOptions() async {
    final settings = SecuritySettingsService.instance;
    final hasSession = await SessionService.instance.hasValidSession();
    final biometric = hasSession && await settings.biometricEnabled();
    final pin = hasSession && await settings.pinEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = biometric;
      _pinEnabled = pin;
    });
  }
}
