import '../security/session_service.dart';
import '../security/security_settings_service.dart';

class AppBootstrap {
  static Future<void> init() async {
    await Future.wait([
      SessionService.instance.loadCachedSession(),
      SecuritySettingsService.instance.load(),
    ]);
  }
}
