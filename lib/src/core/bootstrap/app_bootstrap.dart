import '../security/session_service.dart';

class AppBootstrap {
  static Future<void> init() async {
    await SessionService.instance.ensureJwtSecret();
    await SessionService.instance.loadCachedToken();
  }
}
