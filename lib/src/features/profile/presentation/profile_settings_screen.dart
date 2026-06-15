import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/security/security_settings_service.dart';
import '../../../core/security/session_service.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../auth/data/auth_repository.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  bool _biometric = false;
  bool _pin = false;
  bool _autoLogin = true;
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
                const SizedBox(height: 18),
                _field(_name, 'Name', Icons.person_outline),
                _field(_email, 'Email', Icons.mail_outline, readOnly: true),
                _field(_age, 'Age', Icons.cake_outlined, number: true),
                _field(_mobile, 'Mobile Number', Icons.phone_outlined, number: true),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Profile'),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    value: _autoLogin,
                    secondary: const Icon(Icons.login),
                    title: const Text('Auto Login'),
                    subtitle: const Text('Open directly when your saved server session is valid.'),
                    onChanged: (value) async {
                      await SecuritySettingsService.instance.setAutoLoginEnabled(value);
                      await _load();
                    },
                  ),
                ),
                Card(
                  child: SwitchListTile(
                    value: _biometric,
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Unlock'),
                    subtitle: const Text('Enable biometric unlock on the login screen.'),
                    onChanged: _setBiometric,
                  ),
                ),
                Card(
                  child: SwitchListTile(
                    value: _pin,
                    secondary: const Icon(Icons.pin_outlined),
                    title: const Text('Secure PIN Unlock'),
                    subtitle: const Text('Enable local PIN unlock on the login screen.'),
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

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      ),
    );
  }

  Future<void> _load() async {
    final service = SecuritySettingsService.instance;
    setState(() => _loading = true);
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (user != null) {
      _name.text = user.name;
      _email.text = user.email;
      _age.text = user.age?.toString() ?? '';
      _mobile.text = user.mobile;
    }
    _biometric = await service.biometricEnabled();
    _pin = await service.pinEnabled();
    _autoLogin = await service.autoLoginEnabled();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final user = await ref.read(authRepositoryProvider).updateProfile(
          name: _name.text,
          age: int.tryParse(_age.text.trim()),
          mobile: _mobile.text,
        );
    _name.text = user.name;
    _age.text = user.age?.toString() ?? '';
    _mobile.text = user.mobile;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
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
