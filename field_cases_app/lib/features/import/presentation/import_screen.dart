import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/arabic_format.dart';
import '../../cases/domain/case_enums.dart';
import '../../packages/domain/package_models.dart';
import '../../supervisor/presentation/batch_review_screen.dart';
import '../data/import_service.dart';
import '../domain/duplicate_detector.dart';

/// اختيار ملف الحزمة من الجوال (Files / Downloads). مجرد في واجهة لتسهيل الاختبار.
typedef PackageFilePicker = Future<String?> Function();

Future<String?> pickPackageFile() async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  return files.isEmpty ? null : files.first.path;
}

final packageFilePickerProvider = Provider<PackageFilePicker>(
  (ref) => pickPackageFile,
);

/// "استيراد بيانات": اختيار الملف ← فحص الحزمة ← معاينة ← اعتماد الاستيراد.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportReport? _report;
  bool _busy = false;
  String? _busyText;

  @override
  void dispose() {
    final report = _report;
    // نسخة حزمة فُحصت ولم تُستورد تُحذف عند الخروج.
    if (report != null) ref.read(importServiceProvider).discard(report);
    super.dispose();
  }

  Future<void> _pick() async {
    final path = await ref.read(packageFilePickerProvider)();
    if (path == null || !mounted) return;
    if (!path.toLowerCase().endsWith('.${PackageFormat.extension}')) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('امتداد غير معتاد'),
          content: const Text(
            'الملف ليس بامتداد ‎.casepkg‎. قد يكون WhatsApp غيّر اسمه. هل تريد فحصه؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('فحص'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    final previous = _report;
    setState(() {
      _busy = true;
      _busyText = 'جارٍ فحص الحزمة…';
      _report = null;
    });
    if (previous != null) {
      await ref.read(importServiceProvider).discard(previous);
    }
    try {
      final report = await ref.read(importServiceProvider).prepare(path);
      if (mounted) setState(() => _report = report);
    } on Exception catch (e) {
      _show('تعذر فحص الملف: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    final report = _report;
    if (report == null) return;
    setState(() {
      _busy = true;
      _busyText = 'جارٍ الاستيراد…';
    });
    try {
      final outcome = await ref.read(importServiceProvider).commit(report);
      if (!mounted) return;
      setState(() {
        _report = null;
        _busy = false;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, size: 48),
          title: const Text('تم الاستيراد'),
          content: Text(
            'أُضيفت ${outcome.importedCases} حالة و${outcome.importedAttachments} صورة '
            'إلى الدفعات الواردة للمراجعة.'
            '${outcome.pendingDecisions > 0 ? '\n${outcome.pendingDecisions} حالة لها نسخة أحدث تنتظر قرارك.' : ''}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('مراجعة الدفعة'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BatchReviewScreen(batchId: outcome.batchId),
        ),
      );
    } on Exception catch (e) {
      if (mounted) setState(() => _busy = false);
      _show('تعذر الاستيراد ولم يُدخل أي شيء: $e');
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('استيراد بيانات')),
      body: _busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_busyText ?? ''),
                ],
              ),
            )
          : report == null
          ? _PickPrompt(onPick: _pick)
          : _ReportView(report: report, onPickAnother: _pick),
      bottomNavigationBar: report == null || _busy
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: report.canImport ? _commit : null,
                  icon: const Icon(Icons.download_done),
                  label: const Text('اعتماد الاستيراد'),
                ),
              ),
            ),
    );
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.move_to_inbox, size: 80, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'استيراد حزمة حالات',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'احفظ ملف ‎.casepkg‎ الوارد عبر WhatsApp في "الملفات"، ثم اختره هنا. '
              'سيُفحص الملف قبل إدخال أي بيانات.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open),
              label: const Text('اختيار ملف'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report, required this.onPickAnother});

  final ImportReport report;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = report.manifest;
    final errors = report.errors;

    Widget stat(String label, int value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (m != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدفعة: ${m.source.orgName ?? m.source.enteredBy ?? 'غير محددة'}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أُنشئت ${ArabicFormat.dateTime(m.createdAt)}'
                    '${m.source.enteredBy == null ? '' : ' • المدخل ${m.source.enteredBy}'}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const Divider(height: 24),
                  stat('عدد الحالات', m.caseCount),
                  stat('الصور', m.imageCount),
                  if (report.items.isNotEmpty) ...[
                    const Divider(height: 24),
                    stat(
                      'جديدة',
                      report.count(ImportClassification.newCase),
                      color: scheme.primary,
                    ),
                    stat(
                      'موجودة مسبقًا',
                      report.count(ImportClassification.duplicate),
                    ),
                    stat(
                      'لها نسخة أحدث',
                      report.count(ImportClassification.newer),
                      color: scheme.tertiary,
                    ),
                    if (report.count(ImportClassification.conflict) > 0)
                      stat(
                        'نسخة مختلفة',
                        report.count(ImportClassification.conflict),
                        color: scheme.tertiary,
                      ),
                    if (report.count(ImportClassification.older) > 0)
                      stat(
                        'نسخة أقدم (تُتجاهل)',
                        report.count(ImportClassification.older),
                      ),
                  ],
                  stat(
                    'أخطاء',
                    errors.length,
                    color: errors.isEmpty ? null : scheme.error,
                  ),
                ],
              ),
            ),
          ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in errors.take(10))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $e',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  if (errors.length > 10)
                    Text(
                      'و${errors.length - 10} أخطاء أخرى',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (errors.isEmpty && !report.canImport)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'لا توجد حالات جديدة في هذه الحزمة؛ كل حالاتها موجودة مسبقًا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        if (report.pendingDecision > 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'الحالات التي لها نسخة أحدث لن تستبدل الموجودة الآن؛ ستظهر في الدفعة '
              'لتقرر بشأنها.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        if (report.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            title: Text('معاينة الحالات (${report.items.length})'),
            children: [
              for (final item in report.items)
                ListTile(
                  dense: true,
                  title: Text(item.packagedCase.caseType.label),
                  subtitle: Text(
                    '${ArabicFormat.dateTime(item.packagedCase.occurredAt)} • '
                    '${item.packagedCase.governorate?.label ?? item.packagedCase.locationText ?? ''}',
                  ),
                  trailing: Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(DuplicateDetector.label(item.classification)),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onPickAnother,
          icon: const Icon(Icons.folder_open),
          label: const Text('اختيار ملف آخر'),
        ),
      ],
    );
  }
}
