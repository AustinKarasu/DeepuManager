import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static String hash(String input, {String? salt}) {
    final actualSalt = salt ?? _salt();
    final bytes = utf8.encode('$actualSalt:$input');
    final digest = sha256.convert(bytes).toString();
    return '$actualSalt:$digest';
  }

  static bool verify(String input, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    return hash(input, salt: parts.first) == stored;
  }

  static String _salt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
