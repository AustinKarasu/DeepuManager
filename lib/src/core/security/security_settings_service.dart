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
  static const _autoLoginKey = 'deepu_auto_login_enabled';
  bool? _biometricEnabled;
  bool? _pinEnabled;
  bool? _autoLoginEnabled;
  String? _pinHash;

  Future<void> load() async {
    final values = await Future.wait([
      _storage.read(key: _biometricEnabledKey),
      _storage.read(key: _pinEnabledKey),
      _storage.read(key: _pinHashKey),
      _storage.read(key: _autoLoginKey),
    ]);
    _biometricEnabled = values[0] == 'true';
    _pinEnabled = values[1] == 'true' && values[2] != null;
    _pinHash = values[2];
    _autoLoginEnabled = values[3] != 'false';
  }

  Future<bool> biometricEnabled() async {
    return _biometricEnabled ?? await _readBiometricEnabled();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> pinEnabled() async {
    return _pinEnabled ?? await _readPinEnabled();
  }

  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('Secure PIN must be at least 4 digits');
    }
    _pinHash = _hash(pin);
    _pinEnabled = true;
    await _storage.write(key: _pinHashKey, value: _pinHash);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  Future<void> disablePin() async {
    _pinEnabled = false;
    _pinHash = null;
    await _storage.write(key: _pinEnabledKey, value: 'false');
    await _storage.delete(key: _pinHashKey);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = _pinHash ?? await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    return _hash(pin, salt: parts.first) == stored;
  }

  Future<bool> autoLoginEnabled() async {
    return _autoLoginEnabled ?? await _readAutoLoginEnabled();
  }

  Future<void> setAutoLoginEnabled(bool enabled) async {
    _autoLoginEnabled = enabled;
    await _storage.write(key: _autoLoginKey, value: enabled.toString());
  }

  Future<bool> _readBiometricEnabled() async {
    _biometricEnabled = await _storage.read(key: _biometricEnabledKey) == 'true';
    return _biometricEnabled!;
  }

  Future<bool> _readPinEnabled() async {
    final values = await Future.wait([
      _storage.read(key: _pinEnabledKey),
      _storage.read(key: _pinHashKey),
    ]);
    _pinHash = values[1];
    _pinEnabled = values[0] == 'true' && _pinHash != null;
    return _pinEnabled!;
  }

  Future<bool> _readAutoLoginEnabled() async {
    _autoLoginEnabled = await _storage.read(key: _autoLoginKey) != 'false';
    return _autoLoginEnabled!;
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
