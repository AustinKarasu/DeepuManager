import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/security/password_hasher.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

class AdminRepository {
  final _uuid = const Uuid();

  Future<List<Map<String, Object?>>> users() {
    return AppDatabase.instance.db.query('users', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, Object?>>> requests() {
    return AppDatabase.instance.db.query(
      'access_requests',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> auditLogs() {
    return AppDatabase.instance.db.query(
      'audit_logs',
      orderBy: 'created_at DESC',
      limit: 100,
    );
  }

  Future<void> approveRequest(Map<String, Object?> request) async {
    final now = DateTime.now().toIso8601String();
    await AppDatabase.instance.db.transaction((txn) async {
      await txn.insert('users', {
        'id': _uuid.v4(),
        'email': request['email'],
        'name': request['name'],
        'password_hash': PasswordHasher.hash('ChangeMe@123'),
        'pin_hash': PasswordHasher.hash('123456'),
        'role': 'staff',
        'status': 'active',
        'device_id': 'approved-device',
        'biometric_enabled': 0,
        'created_at': now,
        'updated_at': now,
      });
      await txn.update(
        'access_requests',
        {'status': 'approved', 'reviewed_at': now},
        where: 'id = ?',
        whereArgs: [request['id']],
      );
      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'user_id': 'admin-default',
        'action': 'approve_access',
        'entity': 'access_requests',
        'entity_id': request['id'],
        'metadata': '{}',
        'created_at': now,
      });
    });
  }

  Future<void> denyRequest(String id) async {
    await AppDatabase.instance.db.update(
      'access_requests',
      {'status': 'denied', 'reviewed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteUser(String id) {
    return AppDatabase.instance.db.delete(
      'users',
      where: 'id = ? AND role != ?',
      whereArgs: [id, 'admin'],
    );
  }
}
