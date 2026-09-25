import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/security/pin_hasher.dart';

/// إدخال رمز PIN من 6 أرقام (مخفي). يُرسل تلقائيًا عند اكتمال الأرقام.
class PinDialog extends StatefulWidget {
  const PinDialog({super.key, required this.title, this.message, this.error});

  final String title;
  final String? message;
  final String? error;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? error,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PinDialog(title: title, message: message, error: error),
    );
  }

  /// يطلب رمزًا جديدًا مرتين للتأكيد. يعيد null عند الإلغاء.
  static Future<String?> createNew(BuildContext context) async {
    String? error;
    while (true) {
      if (!context.mounted) return null;
      final first = await show(
        context,
        title: 'رمز المشرف الجديد',
        message:
            'اختر رمزًا من ${PinHasher.pinLength} أرقام لحماية وضع المشرف.',
        error: error,
      );
      if (first == null || !context.mounted) return null;
      final second = await show(
        context,
        title: 'تأكيد الرمز',
        message: 'أعد إدخال الرمز نفسه.',
      );
      if (second == null) return null;
      if (first == second) return first;
      error = 'الرمزان غير متطابقين، حاول مرة أخرى';
    }
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (PinHasher.isValidFormat(_controller.text)) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: const Icon(Icons.lock_outline, size: 36),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            obscuringCharacter: '●',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.number,
            maxLength: PinHasher.pinLength,
            style: const TextStyle(fontSize: 28, letterSpacing: 12),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: ''),
            onChanged: (value) {
              setState(() {});
              if (value.length == PinHasher.pinLength) _submit();
            },
            onSubmitted: (_) => _submit(),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: PinHasher.isValidFormat(_controller.text) ? _submit : null,
          child: const Text('متابعة'),
        ),
      ],
    );
  }
}
