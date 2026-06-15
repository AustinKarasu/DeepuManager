import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/security/session_service.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final _uuid = const Uuid();

  Future<AppUser> loginWithPassword(String email, String password) async {
    final rows = await AppDatabase.instance.db.query(
      'users',
      where: 'email = ? AND status = ?',
      whereArgs: [email.trim().toLowerCase(), 'active'],
      limit: 1,
    );
    if (rows.isEmpty) throw AuthException('Account not found or not approved');
    final row = rows.first;
    if (!PasswordHasher.verify(password, row['password_hash'] as String)) {
      throw AuthException('Invalid password');
    }
    final user = AppUser.fromMap(row);
    await SessionService.instance.createSession(
      userId: user.id,
      email: user.email,
      role: user.role,
    );
    await _audit(user.id, 'login', 'users', user.id);
    return user;
  }

  Future<AppUser> loginWithPin(String email, String pin) async {
    final rows = await AppDatabase.instance.db.query(
      'users',
      where: 'email = ? AND status = ?',
      whereArgs: [email.trim().toLowerCase(), 'active'],
      limit: 1,
    );
    if (rows.isEmpty) throw AuthException('Account not found or not approved');
    final hash = rows.first['pin_hash'] as String?;
    if (hash == null || !PasswordHasher.verify(pin, hash)) {
      throw AuthException('Invalid secure PIN');
    }
    final user = AppUser.fromMap(rows.first);
    await SessionService.instance.createSession(
      userId: user.id,
      email: user.email,
      role: user.role,
    );
    return user;
  }

  Future<void> requestAccess({
    required String email,
    required String name,
    required String reason,
  }) async {
    final now = DateTime.now().toIso8601String();
    await AppDatabase.instance.db.insert('access_requests', {
      'id': _uuid.v4(),
      'email': email.trim().toLowerCase(),
      'name': name.trim(),
      'reason': reason.trim(),
      'status': 'pending',
      'created_at': now,
    });
  }

  Future<AppUser?> currentUser() async {
    final claims = await SessionService.instance.claimsOrNull();
    final userId = claims?['sub'];
    if (userId is! String) return null;
    final rows = await AppDatabase.instance.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<void> _audit(
    String? userId,
    String action,
    String entity,
    String? entityId,
  ) async {
    await AppDatabase.instance.db.insert('audit_logs', {
      'id': _uuid.v4(),
      'user_id': userId,
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'metadata': '{}',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
