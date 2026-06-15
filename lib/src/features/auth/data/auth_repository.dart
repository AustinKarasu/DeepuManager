import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/session_service.dart';
import 'access_request_tracker.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(apiClientProvider)));

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AppUser> loginWithPassword(String email, String password) async {
    try {
      final response = await _api.post<Map<String, dynamic>>('/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final data = response.data;
      if (data == null) throw AuthException('Invalid server response');
      final userMap = data['user'] as Map<String, Object?>;
      final token = data['token'] as String;
      final user = AppUser.fromApi(userMap);
      SessionService.instance.saveServerSessionFast(
        token: token,
        user: userMap,
      );
      SessionService.instance.persistSessionInBackground(
        token: token,
        user: userMap,
      );
      return user;
    } on DioException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  Future<String> requestAccess({
    required String email,
    required String name,
    required String reason,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>('/access-requests', {
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'reason': reason.trim(),
      });
      final id = response.data?['id']?.toString();
      if (id == null || id.isEmpty) throw AuthException('Invalid server response');
      await AccessRequestTracker.instance.save(id: id, email: email);
      return id;
    } on DioException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  Future<AccessRequestStatus?> pendingAccessStatus() async {
    final pending = await AccessRequestTracker.instance.load();
    if (pending == null) return null;
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/access-requests/${pending.id}/status',
      );
      final data = response.data;
      if (data == null) return null;
      final status = AccessRequestStatus.fromApi(data);
      if (status.isApproved && status.token != null && status.userMap != null) {
        SessionService.instance.saveServerSessionFast(
          token: status.token!,
          user: status.userMap!,
        );
        SessionService.instance.persistSessionInBackground(
          token: status.token!,
          user: status.userMap!,
        );
        await AccessRequestTracker.instance.clear();
      }
      if (status.isDenied) {
        await AccessRequestTracker.instance.clear();
      }
      return status;
    } on DioException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  Future<AppUser?> currentUser() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/me');
      final data = response.data;
      if (data == null) return null;
      await SessionService.instance.saveCachedUser(data);
      return AppUser.fromApi(data);
    } on DioException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  Future<AppUser?> cachedUser() async {
    final cached = await SessionService.instance.cachedUser();
    return cached == null ? null : AppUser.fromApi(cached);
  }

  Future<AppUser> updateProfile({
    required String name,
    required int? age,
    required String mobile,
  }) async {
    final response = await _api.put<Map<String, dynamic>>('/me', {
      'name': name.trim(),
      'age': age,
      'mobile': mobile.trim(),
    });
    final data = response.data;
    if (data == null) throw AuthException('Invalid server response');
    await SessionService.instance.saveCachedUser(data);
    return AppUser.fromApi(data);
  }
}

String _messageFor(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['error'] != null) return data['error'].toString();
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return 'Cannot reach Deepu Manager server. Check internet and try again.';
  }
  return 'Sign in failed. Please try again.';
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AccessRequestStatus {
  const AccessRequestStatus({
    required this.status,
    required this.email,
    required this.name,
    this.token,
    this.userMap,
  });

  final String status;
  final String email;
  final String name;
  final String? token;
  final Map<String, Object?>? userMap;

  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';
  bool get isPending => status == 'pending';

  AppUser? get user => userMap == null ? null : AppUser.fromApi(userMap!);

  factory AccessRequestStatus.fromApi(Map<String, Object?> map) {
    final user = map['user'];
    return AccessRequestStatus(
      status: map['status']?.toString() ?? 'pending',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      token: map['token']?.toString(),
      userMap: user is Map ? Map<String, Object?>.from(user) : null,
    );
  }
}
