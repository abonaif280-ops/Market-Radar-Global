import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/form_attachment.dart';

/// نسخ نص الحالة ومشاركته (مع الصور اختياريًا) عبر قائمة المشاركة في النظام.
abstract final class CaseShareActions {
  static Future<void> copy(
    BuildContext context,
    WidgetRef ref,
    String text,
  ) async {
    if (text.trim().isEmpty) return;
    await ref.read(shareServiceProvider).copyText(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('نُسخ النص')));
  }

  /// إذا كانت هناك صور يُسأل المستخدم: النص فقط أم النص والصور.
  static Future<void> share(
    BuildContext context,
    WidgetRef ref, {
    required String text,
    List<FormAttachment> photos = const [],
    String? subject,
  }) async {
    if (text.trim().isEmpty) return;
    final service = ref.read(shareServiceProvider);
    var withPhotos = false;
    if (photos.isNotEmpty) {
      final choice = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('مشاركة النص فقط'),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('مشاركة النص والصور (${photos.length})'),
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (choice == null) return;
      withPhotos = choice;
    }
    try {
      if (withPhotos) {
        await service.shareTextWithFiles(text, [
          for (final p in photos) p.filePath,
        ], subject: subject);
      } else {
        await service.shareText(text, subject: subject);
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذرت المشاركة: $e')));
    }
  }
}
