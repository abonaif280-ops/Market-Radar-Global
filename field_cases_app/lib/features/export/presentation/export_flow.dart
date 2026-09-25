import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/case_export_service.dart';

/// خطوات التصدير المشتركة (من شاشة التصدير، أو التحديد المتعدد، أو تفاصيل الحالة):
/// ملخص وتأكيد ← إنشاء الحزمة ← مشاركة الملف.
abstract final class ExportFlow {
  /// يعيد true إذا أُنشئت الحزمة.
  static Future<bool> run(
    BuildContext context,
    WidgetRef ref,
    ExportRequest request,
  ) async {
    final service = ref.read(caseExportServiceProvider);
    final preview = await service.preview(request);
    if (!context.mounted) return false;
    if (preview.caseCount == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('لا توجد حالات للتصدير')));
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.inventory_2_outlined, size: 36),
        title: const Text('إنشاء حزمة التصدير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryRow('عدد الحالات', '${preview.caseCount}'),
            _SummaryRow('عدد الصور', '${preview.imageCount}'),
            _SummaryRow('الحجم التقريبي', formatBytes(preview.totalBytes)),
            const SizedBox(height: 12),
            const Text(
              'ستُحفظ الحالات والصور في ملف واحد ‎.casepkg‎ يمكنك مشاركته '
              'عبر WhatsApp أو حفظه في الملفات.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إنشاء الحزمة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('جارٍ إنشاء الحزمة…')),
            ],
          ),
        ),
      ),
    );

    ExportResult result;
    try {
      result = await service.export(request);
    } on Exception catch (e) {
      navigator.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر إنشاء الحزمة: $e')));
      }
      return false;
    }
    navigator.pop();
    if (!context.mounted) return true;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isDismissible: true,
      builder: (context) => _ResultSheet(result: result),
    );
    return true;
  }

  /// اسم الملف مختلط (عربي + تاريخ + امتداد)؛ يُعزل الجزء اللاتيني حتى يُقرأ
  /// اسم الجهة أولًا ثم التاريخ داخل الواجهة العربية.
  static String displayFileName(String name) {
    final match = RegExp(r'^(.*?)(\d{8}_\d{4}\..+)$').firstMatch(name);
    if (match == null) return name;
    return '${match.group(1)}\u2066${match.group(2)}\u2069';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} ك.ب';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.result});

  final ExportResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final m = result.manifest;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle, color: scheme.primary, size: 56),
            const SizedBox(height: 8),
            Text(
              'أُنشئت الحزمة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SelectableText(
              ExportFlow.displayFileName(result.fileName),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${m.caseCount} حالة • ${m.imageCount} صورة • '
              '${ExportFlow.formatBytes(result.sizeBytes)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref
                  .read(shareServiceProvider)
                  .shareFile(
                    result.file.path,
                    text:
                        'حزمة حالات: ${m.caseCount} حالة، ${m.imageCount} صورة',
                  ),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة الملف'),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر WhatsApp لإرساله للمشرف، أو "حفظ في الملفات".',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );
  }
}
