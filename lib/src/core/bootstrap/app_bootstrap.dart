import '../database/app_database.dart';
import '../security/session_service.dart';

class AppBootstrap {
  static Future<void> init() async {
    await AppDatabase.instance.open();
    await SessionService.instance.ensureJwtSecret();
  }
}
