import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecuritySettingsService {
  SecuritySettingsService._();

  static final SecuritySettingsService instance = SecuritySettingsService._();
  static const _storage = FlutterSecureStorage();
  static const _biometricEnabledKey = 'deepu_biometric_enabled';
  static const _pinEnabledKey = 'deepu_pin_enabled';
  static const _pinHashKey = 'deepu_pin_hash';

  Future<bool> biometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> pinEnabled() async {
    return await _storage.read(key: _pinEnabledKey) == 'true' &&
        await _storage.read(key: _pinHashKey) != null;
  }

  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('Secure PIN must be at least 4 digits');
    }
    await _storage.write(key: _pinHashKey, value: _hash(pin));
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  Future<void> disablePin() async {
    await _storage.write(key: _pinEnabledKey, value: 'false');
    await _storage.delete(key: _pinHashKey);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    return _hash(pin, salt: parts.first) == stored;
  }

  String _hash(String value, {String? salt}) {
    final actualSalt = salt ?? _salt();
    final digest = sha256.convert(utf8.encode('$actualSalt:$value'));
    return '$actualSalt:$digest';
  }

  String _salt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
