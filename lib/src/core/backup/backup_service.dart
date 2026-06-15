import 'dart:io';

import 'package:path_provider/path_provider.dart';

class BackupService {
  Future<File> createLocalBackup() async {
    final docs = await getApplicationDocumentsDirectory();
    final source = File('${docs.path}/deepu_logger.db');
    final backupDir = Directory('${docs.path}/backups');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return source.copy('${backupDir.path}/deepu_logger_$stamp.db');
  }

  Future<void> restoreBackup(File backup) async {
    final docs = await getApplicationDocumentsDirectory();
    await backup.copy('${docs.path}/deepu_logger.db');
  }
}
