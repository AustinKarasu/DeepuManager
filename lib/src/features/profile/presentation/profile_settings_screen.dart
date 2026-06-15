import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/security/security_settings_service.dart';
import '../../../core/security/session_service.dart';
import '../../../core/widgets/brand_logo.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _biometric = false;
  bool _pin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: BrandLogo(size: 72)),
                const SizedBox(height: 12),
                Text(
                  'Deepu Manager',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: SwitchListTile(
                    value: _biometric,
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Unlock'),
                    subtitle: const Text('Show biometric unlock on login after password sign-in.'),
                    onChanged: _setBiometric,
                  ),
                ),
                Card(
                  child: SwitchListTile(
                    value: _pin,
                    secondary: const Icon(Icons.pin_outlined),
                    title: const Text('Secure PIN Unlock'),
                    subtitle: const Text('Show secure PIN unlock on login after setting a PIN.'),
                    onChanged: _setPin,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    await SessionService.instance.clear();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
    );
  }

  Future<void> _load() async {
    final service = SecuritySettingsService.instance;
    setState(() => _loading = true);
    _biometric = await service.biometricEnabled();
    _pin = await service.pinEnabled();
    setState(() => _loading = false);
  }

  Future<void> _setBiometric(bool enabled) async {
    if (enabled && !await BiometricService.instance.canUseBiometrics()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrics are not available on this device.')),
      );
      return;
    }
    await SecuritySettingsService.instance.setBiometricEnabled(enabled);
    await _load();
  }

  Future<void> _setPin(bool enabled) async {
    if (!enabled) {
      await SecuritySettingsService.instance.disablePin();
      await _load();
      return;
    }
    final pin = await _pinDialog();
    if (pin == null) return;
    await SecuritySettingsService.instance.setPin(pin);
    await _load();
  }

  Future<String?> _pinDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Secure PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
