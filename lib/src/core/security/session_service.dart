import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'security_settings_service.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();
  static const _storage = FlutterSecureStorage();
  static const _jwtKey = 'deepu_logger_session';
  static const _userKey = 'deepu_logger_user';
  String? tokenSync;
  Map<String, dynamic>? _userSync;

  Future<bool> hasValidSession() async {
    if (!await SecuritySettingsService.instance.autoLoginEnabled()) return false;
    tokenSync ??= await _storage.read(key: _jwtKey);
    return tokenSync != null && tokenSync!.isNotEmpty;
  }

  Future<bool> hasSavedSession() async {
    tokenSync ??= await _storage.read(key: _jwtKey);
    return tokenSync != null && tokenSync!.isNotEmpty;
  }

  Future<void> saveServerSession({
    required String token,
    required Map<String, Object?> user,
  }) async {
    saveServerSessionFast(token: token, user: user);
    await persistSession(token: token, user: user);
  }

  void saveServerSessionFast({
    required String token,
    required Map<String, Object?> user,
  }) {
    tokenSync = token;
    _userSync = Map<String, dynamic>.from(user);
  }

  void persistSessionInBackground({
    required String token,
    required Map<String, Object?> user,
  }) {
    persistSession(token: token, user: user).catchError((Object error, StackTrace stack) {
      log('Could not persist session', error: error, stackTrace: stack);
    });
  }

  Future<void> persistSession({
    required String token,
    required Map<String, Object?> user,
  }) async {
    await Future.wait([
      _storage.write(key: _jwtKey, value: token),
      _storage.write(key: _userKey, value: jsonEncode(user)),
    ]);
  }

  Map<String, dynamic>? cachedUserSync() => _userSync;

  Future<Map<String, dynamic>?> cachedUser() async {
    if (_userSync != null) return _userSync;
    final value = await _storage.read(key: _userKey);
    if (value == null) return null;
    _userSync = jsonDecode(value) as Map<String, dynamic>;
    return _userSync;
  }

  Future<void> saveCachedUser(Map<String, Object?> user) async {
    _userSync = Map<String, dynamic>.from(user);
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<void> loadCachedSession() async {
    final values = await Future.wait([
      _storage.read(key: _jwtKey),
      _storage.read(key: _userKey),
    ]);
    tokenSync = values[0];
    final userValue = values[1];
    if (userValue != null) {
      _userSync = jsonDecode(userValue) as Map<String, dynamic>;
    }
  }

  Future<void> loadCachedToken() async {
    await loadCachedSession();
  }

  Future<void> clear() async {
    tokenSync = null;
    _userSync = null;
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _userKey);
  }
}
