import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// المشاركة عبر قائمة المشاركة في النظام (Share Sheet): المستخدم يختار WhatsApp
/// أو أي تطبيق آخر بنفسه. لا إرسال تلقائي ولا أي API خارجي.
abstract interface class ShareService {
  Future<void> shareText(String text, {String? subject});

  Future<void> shareTextWithFiles(
    String text,
    List<String> filePaths, {
    String? subject,
  });

  Future<void> copyText(String text);
}

class SystemShareService implements ShareService {
  const SystemShareService();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<void> shareTextWithFiles(
    String text,
    List<String> filePaths, {
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        files: [for (final path in filePaths) XFile(path)],
      ),
    );
  }

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
