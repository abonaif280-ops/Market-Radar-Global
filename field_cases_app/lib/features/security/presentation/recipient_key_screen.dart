import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/providers.dart';
import '../../../core/crypto/key_manager.dart';

/// مسح رمز QR من الكاميرا. مجرد في واجهة ليسهل استبداله في الاختبارات.
typedef KeyScanner = Future<String?> Function(BuildContext context);

Future<String?> scanKeyWithCamera(BuildContext context) {
  return Navigator.of(context)
      .push<String>(MaterialPageRoute(builder: (_) => const _ScannerScreen()));
}

final keyScannerProvider = Provider<KeyScanner>((ref) => scanKeyWithCamera);

/// لدى الموظف: ضبط مفتاح المشرف الذي تُشفَّر له الحزم المصدّرة.
class RecipientKeyScreen extends ConsumerWidget {
  const RecipientKeyScreen({super.key});

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    String? payload,
  ) async {
    if (payload == null) return;
    final key = RecipientKey.tryParse(payload);
    if (key == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرمز ليس مفتاح مشرف صالحًا')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 40),
        title: const Text('طابق البصمة مع المشرف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (key.label != null) Text(key.label!),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                key.fingerprint,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'تأكد أن نفس البصمة ظاهرة على جوال المشرف قبل الحفظ.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('غير مطابقة'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('البصمة مطابقة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(keyManagerProvider).setRecipientKey(key);
    ref.invalidate(recipientKeyProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('حُفظ مفتاح المشرف. الحزم ستُشفَّر له.')),
    );
  }

  Future<void> _paste(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لصق مفتاح المشرف'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'FCKEY1|...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (context.mounted) await _accept(context, ref, text);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة مفتاح المشرف؟'),
        content: const Text('الحزم المصدّرة بعد ذلك لن تكون مشفرة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(keyManagerProvider).clearRecipientKey();
    ref.invalidate(recipientKeyProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(recipientKeyProvider);
    final scheme = Theme.of(context).colorScheme;
    final current = key.value;

    return Scaffold(
      appBar: AppBar(title: const Text('مفتاح التشفير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: current == null
                ? scheme.errorContainer
                : scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    current == null ? Icons.lock_open : Icons.lock,
                    size: 48,
                    color: current == null ? scheme.error : scheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current == null
                        ? 'لم يُضبط مفتاح المشرف'
                        : 'الحزم تُشفَّر لـ: ${current.label ?? 'المشرف'}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    current == null
                        ? 'الحزم المصدّرة ستكون غير مشفرة ويمكن لأي شخص يصله الملف قراءتها.'
                        : 'البصمة: ${current.fingerprint}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final payload = await ref.read(keyScannerProvider)(context);
              if (context.mounted) await _accept(context, ref, payload);
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('مسح رمز QR من جوال المشرف'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _paste(context, ref),
            icon: const Icon(Icons.content_paste),
            label: const Text('لصق المفتاح كنص'),
          ),
          if (current != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _remove(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: const Text('إزالة المفتاح'),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'لا يمكن فتح الحزمة المشفرة إلا على جوال المشرف صاحب هذا المفتاح. '
            'لا يُرسل أي مفتاح مع الحزمة.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح مفتاح المشرف')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final value = capture.barcodes
              .map((b) => b.rawValue)
              .whereType<String>()
              .where((v) => v.startsWith('FCKEY1|'))
              .firstOrNull;
          if (value == null) return;
          _done = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
