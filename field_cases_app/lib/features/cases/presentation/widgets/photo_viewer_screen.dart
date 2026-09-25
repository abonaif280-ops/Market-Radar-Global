import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/form_attachment.dart';

/// عرض الصور بالحجم الكامل مع التكبير والتنقل بينها.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.attachments,
    this.initialIndex = 0,
  });

  final List<FormAttachment> attachments;
  final int initialIndex;

  static Future<void> open(
    BuildContext context,
    List<FormAttachment> attachments,
    int index,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PhotoViewerScreen(attachments: attachments, initialIndex: index),
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.attachments[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          current.fileName ??
              'صورة ${_index + 1} من ${widget.attachments.length}',
          style: const TextStyle(color: Colors.white, fontSize: 15),
          textDirection: TextDirection.ltr,
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.attachments.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(widget.attachments[i].filePath),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
