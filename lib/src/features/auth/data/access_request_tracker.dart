import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingAccessRequest {
  const PendingAccessRequest({
    required this.id,
    required this.email,
  });

  final String id;
  final String email;
}

class AccessRequestTracker {
  AccessRequestTracker._();

  static final AccessRequestTracker instance = AccessRequestTracker._();
  static const _storage = FlutterSecureStorage();
  static const _idKey = 'deepu_pending_access_request_id';
  static const _emailKey = 'deepu_pending_access_request_email';

  Future<void> save({required String id, required String email}) async {
    await Future.wait([
      _storage.write(key: _idKey, value: id),
      _storage.write(key: _emailKey, value: email.trim().toLowerCase()),
    ]);
  }

  Future<PendingAccessRequest?> load() async {
    final values = await Future.wait([
      _storage.read(key: _idKey),
      _storage.read(key: _emailKey),
    ]);
    final id = values[0];
    final email = values[1];
    if (id == null || id.isEmpty || email == null || email.isEmpty) return null;
    return PendingAccessRequest(id: id, email: email);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _idKey),
      _storage.delete(key: _emailKey),
    ]);
  }
}
