import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.notes,
  });

  final String version;
  final String apkUrl;
  final String notes;

  factory AppUpdateInfo.fromMap(Map<String, Object?> map) => AppUpdateInfo(
        version: map['version']?.toString() ?? '',
        apkUrl: map['apkUrl']?.toString() ?? '',
        notes: map['notes']?.toString() ?? '',
      );
}

class UpdateService {
  UpdateService({ApiClient? api, Dio? dio})
      : _api = api ?? ApiClient(),
        _dio = dio ?? Dio();

  static const currentVersion = '1.0.8';
  final ApiClient _api;
  final Dio _dio;

  Future<AppUpdateInfo?> check() async {
    final response = await _api.get<Map<String, dynamic>>('/app/latest');
    final data = response.data;
    if (data == null) return null;
    final info = AppUpdateInfo.fromMap(data);
    if (info.apkUrl.isEmpty || !_isNewer(info.version, currentVersion)) return null;
    return info;
  }

  Future<File> download(AppUpdateInfo info) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Deepu-Manager-${info.version}.apk');
    await _dio.download(info.apkUrl, file.path);
    return file;
  }

  Future<void> openInstaller(File file) async {
    await OpenFilex.open(file.path);
  }

  bool _isNewer(String remote, String current) {
    final r = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }
}
