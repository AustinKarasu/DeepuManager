import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/session_service.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: const String.fromEnvironment(
                'DEEPU_API_BASE_URL',
                defaultValue: '',
              ),
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, Object?>? query}) {
    return _dio.get<T>(
      path,
      queryParameters: query,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<T>> post<T>(String path, Map<String, Object?> body) {
    return _dio.post<T>(
      path,
      data: body,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<T>> put<T>(String path, Map<String, Object?> body) {
    return _dio.put<T>(
      path,
      data: body,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path, options: Options(headers: _headers()));
  }

  Map<String, String> _headers() {
    final token = SessionService.instance.tokenSync;
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }
}
