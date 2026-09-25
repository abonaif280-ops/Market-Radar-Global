import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/form_attachment.dart';
import 'photo_viewer_screen.dart';

/// شبكة مصغرات الصور. تعرض المصغرة (thumbnail) فقط وليس الصورة الكاملة.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.attachments, this.onRemove});

  final List<FormAttachment> attachments;

  /// إذا كانت null تُعرض الشبكة للقراءة فقط.
  final ValueChanged<FormAttachment>? onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () =>
                    PhotoViewerScreen.open(context, attachments, index),
                child: Image.file(
                  File(attachment.previewPath),
                  fit: BoxFit.cover,
                  // يحد من استهلاك الذاكرة حتى لو لم تتوفر مصغرة.
                  cacheWidth: 320,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              PositionedDirectional(
                top: 4,
                end: 4,
                child: IconButton.filled(
                  tooltip: 'حذف الصورة',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                  ),
                  iconSize: 20,
                  onPressed: () => onRemove!(attachment),
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        );
      },
    );
  }
}
