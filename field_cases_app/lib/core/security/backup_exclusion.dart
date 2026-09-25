import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// يستبعد مجلدات التطبيق من نسخ iCloud الاحتياطي (iOS فقط).
///
/// في Android النسخ السحابي معطل أصلًا (allowBackup=false +
/// data_extraction_rules). الفشل هنا لا يوقف التطبيق لكنه يُسجَّل للمطور محليًا.
abstract final class BackupExclusion {
  static const _channel = MethodChannel('field_cases/backup_exclusion');

  static Future<void> exclude(Iterable<Directory> directories) async {
    if (!Platform.isIOS) return;
    for (final dir in directories) {
      try {
        if (!await dir.exists()) await dir.create(recursive: true);
        await _channel.invokeMethod<bool>('exclude', dir.path);
      } on PlatformException catch (e) {
        debugPrint('backup exclusion failed for ${dir.path}: ${e.message}');
      }
    }
  }
}
