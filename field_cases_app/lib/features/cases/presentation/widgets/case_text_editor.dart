import 'package:flutter/material.dart';

/// بطاقة نص الحالة في المعاينة: النص المولد قابل للتعديل، مع نسخ ومشاركة وإعادة صياغة.
class CaseTextEditor extends StatefulWidget {
  const CaseTextEditor({
    super.key,
    required this.text,
    required this.isEdited,
    required this.onChanged,
    required this.onRegenerate,
    required this.onCopy,
    required this.onShare,
  });

  final String text;
  final bool isEdited;
  final ValueChanged<String> onChanged;
  final VoidCallback onRegenerate;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  State<CaseTextEditor> createState() => _CaseTextEditorState();
}

class _CaseTextEditorState extends State<CaseTextEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(CaseTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث من الخارج (إعادة الصياغة) وليس من الكتابة.
    if (widget.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نص الحالة',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (widget.isEdited)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('معدّل يدويًا'),
                    backgroundColor: scheme.tertiaryContainer,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 14,
              style: const TextStyle(fontSize: 17, height: 1.7),
              decoration: const InputDecoration(
                hintText: 'سيظهر هنا النص المولد تلقائيًا',
              ),
              onChanged: widget.onChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCopy,
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ النص'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة'),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: widget.onRegenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة الصياغة من البيانات'),
            ),
          ],
        ),
      ),
    );
  }
}
