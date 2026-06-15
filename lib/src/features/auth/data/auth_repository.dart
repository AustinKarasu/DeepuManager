import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/session_service.dart';
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
      final user = AppUser.fromApi(data['user'] as Map<String, dynamic>);
      await SessionService.instance.saveServerSession(
        token: data['token'] as String,
        user: data['user'] as Map<String, Object?>,
      );
      return user;
    } on DioException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  Future<void> requestAccess({
    required String email,
    required String name,
    required String reason,
  }) async {
    try {
      await _api.post('/access-requests', {
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'reason': reason.trim(),
      });
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
    } catch (_) {
      final cached = await SessionService.instance.cachedUser();
      return cached == null ? null : AppUser.fromApi(cached);
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
