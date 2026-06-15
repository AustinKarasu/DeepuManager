import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../security/session_service.dart';

class SyncService {
  SyncService({
    Dio? dio,
    this.baseUrl = const String.fromEnvironment('DEEPU_API_BASE_URL'),
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;
  final _uuid = const Uuid();

  Future<void> enqueue(String method, String path, Map<String, Object?> payload) {
    return AppDatabase.instance.db.insert('sync_queue', {
      'id': _uuid.v4(),
      'method': method,
      'path': path,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> flush() async {
    if (baseUrl.isEmpty) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    final token = await SessionService.instance.claimsOrNull();
    if (token == null) return;
    final rows = await AppDatabase.instance.db.query('sync_queue', orderBy: 'created_at ASC');
    for (final row in rows) {
      try {
        await _dio.request<Object?>(
          '$baseUrl${row['path']}',
          data: jsonDecode(row['payload'] as String),
          options: Options(
            method: row['method'] as String,
            headers: {'X-DeepuLogger-Offline-Token': token['sub']},
          ),
        );
        await AppDatabase.instance.db.delete('sync_queue', where: 'id = ?', whereArgs: [row['id']]);
      } catch (_) {
        await AppDatabase.instance.db.rawUpdate(
          'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
          [row['id']],
        );
        break;
      }
    }
  }
}
