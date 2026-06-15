import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final adminRepositoryProvider = Provider((ref) {
  return AdminRepository(ref.read(apiClientProvider));
});

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, Object?>>> users() async {
    final response = await _api.get<List<dynamic>>('/admin/users');
    return (response.data ?? [])
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, Object?>>> requests() async {
    final response = await _api.get<List<dynamic>>('/admin/access-requests');
    return (response.data ?? [])
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, Object?>>> auditLogs() async {
    final response = await _api.get<List<dynamic>>('/admin/audit-logs');
    return (response.data ?? [])
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<void> approveRequest(Map<String, Object?> request) async {
    await _api.post('/admin/access-requests/${request['id']}/approve', {});
  }

  Future<void> denyRequest(String id) async {
    await _api.post('/admin/access-requests/$id/deny', {});
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/admin/users/$id');
  }
}
