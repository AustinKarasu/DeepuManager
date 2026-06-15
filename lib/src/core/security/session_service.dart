import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();
  static const _storage = FlutterSecureStorage();
  static const _jwtKey = 'deepu_logger_session';
  static const _userKey = 'deepu_logger_user';
  static const _secretKey = 'deepu_logger_jwt_secret';
  String? tokenSync;

  Future<void> ensureJwtSecret() async {
    final existing = await _storage.read(key: _secretKey);
    if (existing != null) return;
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _storage.write(key: _secretKey, value: base64UrlEncode(bytes));
  }

  Future<String> createSession({
    required String userId,
    required String email,
    required String role,
  }) async {
    final secret = await _secret();
    final header = _encode({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _encode({
      'sub': userId,
      'email': email,
      'role': role,
      'exp': DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch ~/ 1000,
    });
    final signature = _sign('$header.$payload', secret);
    final token = '$header.$payload.$signature';
    await _storage.write(key: _jwtKey, value: token);
    return token;
  }

  Future<bool> hasValidSession() async {
    tokenSync ??= await _storage.read(key: _jwtKey);
    return tokenSync != null && tokenSync!.isNotEmpty;
  }

  Future<Map<String, dynamic>?> claimsOrNull() async {
    final token = await _storage.read(key: _jwtKey);
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final expected = _sign('${parts[0]}.${parts[1]}', await _secret());
      if (parts[2] != expected) return null;
      return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveServerSession({
    required String token,
    required Map<String, Object?> user,
  }) async {
    tokenSync = token;
    await _storage.write(key: _jwtKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> cachedUser() async {
    final value = await _storage.read(key: _userKey);
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> loadCachedToken() async {
    tokenSync = await _storage.read(key: _jwtKey);
  }

  Future<void> clear() async {
    tokenSync = null;
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _userKey);
  }

  Future<String> _secret() async {
    await ensureJwtSecret();
    return (await _storage.read(key: _secretKey))!;
  }

  String _encode(Map<String, Object?> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  String _sign(String body, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return base64Url.encode(hmac.convert(utf8.encode(body)).bytes).replaceAll('=', '');
  }
}
