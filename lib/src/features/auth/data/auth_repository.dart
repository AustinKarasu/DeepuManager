import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_service.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(apiClientProvider)));

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AppUser> loginWithPassword(String email, String password) async {
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
  }

  Future<AppUser> loginWithPin(String email, String pin) async {
    return loginWithPassword(email, pin);
  }

  Future<void> requestAccess({
    required String email,
    required String name,
    required String reason,
  }) async {
    await _api.post('/access-requests', {
      'email': email.trim().toLowerCase(),
      'name': name.trim(),
      'reason': reason.trim(),
    });
  }

  Future<AppUser?> currentUser() async {
    final cached = await SessionService.instance.cachedUser();
    return cached == null ? null : AppUser.fromApi(cached);
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
