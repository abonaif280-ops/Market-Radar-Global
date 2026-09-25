import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/platform/incoming_files.dart';
import '../backup/presentation/backup_screen.dart';
import '../cases/domain/case_enums.dart';
import '../import/presentation/import_screen.dart';

final incomingFilesProvider = Provider<IncomingFiles>(
  (ref) => PlatformIncomingFiles(),
);

final incomingClassifierProvider =
    Provider<Future<IncomingKind> Function(File)>((ref) => classifyIncoming);

/// يستقبل ملفًا فُتح بالتطبيق ويوجهه: حزمة ← الاستيراد (للمشرف)، نسخة ←
/// الاستعادة. يوضع داخل Navigator (حول الشاشة الرئيسية).
class IncomingFileListener extends ConsumerStatefulWidget {
  const IncomingFileListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingFileListener> createState() =>
      _IncomingFileListenerState();
}

class _IncomingFileListenerState extends ConsumerState<IncomingFileListener> {
  StreamSubscription<String>? _subscription;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    final incoming = ref.read(incomingFilesProvider);
    _subscription = incoming.files.listen(_handle);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await incoming.initialFile();
      if (initial != null) await _handle(initial);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handle(String path) async {
    if (!mounted) return;
    final file = File(path);
    if (_handling) {
      // ملف ثانٍ أثناء معالجة الأول: لا نفتح شاشتين فوق بعض.
      await _delete(file);
      _snack('يُعالج ملف آخر حاليًا. أعد فتح الملف بعد الانتهاء.');
      return;
    }
    _handling = true;
    try {
      final kind = await ref.read(incomingClassifierProvider)(file);
      if (!mounted) return;
      switch (kind) {
        case IncomingKind.backup:
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BackupScreen(restorePath: path),
            ),
          );
        case IncomingKind.package:
          final role = await ref
              .read(settingsRepositoryProvider)
              .watchRole()
              .first;
          if (!mounted) return;
          if (role != UserRole.supervisor) {
            await _info(
              'استيراد الحزم للمشرف',
              'هذه حزمة حالات. استيرادها متاح في وضع المشرف فقط '
                  '(الإعدادات ← وضع المشرف).',
            );
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ImportScreen(initialPath: path),
            ),
          );
        case IncomingKind.unsupported:
          await _info(
            'ملف غير مدعوم',
            'التطبيق يفتح حزم الحالات ‎(.casepkg)‎ والنسخ الاحتياطية '
                '‎(.fcbackup)‎ فقط.',
          );
      }
    } finally {
      // النسخة المؤقتة لم تعد لازمة: الاستيراد والاستعادة يعملان على نسخهما.
      await _delete(file);
      _handling = false;
    }
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // ليست مشكلة: المجلد المؤقت يُنظفه النظام.
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _info(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسنًا'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
