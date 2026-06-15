import 'dart:io';

import 'package:flutter/services.dart';

class ShareService {
  ShareService._();

  static final ShareService instance = ShareService._();
  static const _channel = MethodChannel('deepu_manager/share');

  Future<void> shareFile(File file, {String? text}) async {
    await _channel.invokeMethod<void>('shareFile', {
      'path': file.path,
      'text': text ?? 'Deepu Manager stock register sheet',
    });
  }
}
