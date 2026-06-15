import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../network/api_client.dart';

class BackupService {
  BackupService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<File> createBackendSnapshot() async {
    final response = await _api.get<Map<String, dynamic>>('/admin/backup');
    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docs.path}/backups');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${backupDir.path}/deepu_logger_backend_$stamp.json');
    return file.writeAsString(jsonEncode(response.data ?? {}), flush: true);
  }
}
