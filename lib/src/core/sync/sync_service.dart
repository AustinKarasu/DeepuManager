import '../network/api_client.dart';

class SyncService {
  SyncService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<bool> backendAvailable() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/health');
      return response.data?['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
