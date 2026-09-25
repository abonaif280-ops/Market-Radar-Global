import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/arabic_format.dart';
import '../../cases/domain/case_query.dart';
import '../../cases/presentation/cases_list_screen.dart';
import '../data/case_export_service.dart';
import 'export_flow.dart';

/// شاشة التصدير: غير المصدرة، اختيار يدوي، أو فترة زمنية.
/// (تصدير حالة واحدة من شاشة تفاصيلها.)
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _includeDrafts = false;
  ExportPreview? _pending;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final preview = await ref
        .read(caseExportServiceProvider)
        .preview(ExportRequest.unexported(includeDrafts: _includeDrafts));
    if (mounted) setState(() => _pending = preview);
  }

  Future<void> _exportUnexported() async {
    await ExportFlow.run(
      context,
      ref,
      ExportRequest.unexported(includeDrafts: _includeDrafts),
    );
    await _refresh();
  }

  Future<void> _exportRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'فترة التصدير',
    );
    if (picked == null || !mounted) return;
    final range = CaseQuery(
      datePreset: DatePreset.custom,
      customFrom: picked.start,
      customTo: picked.end,
    ).dateRange(now)!;
    await ExportFlow.run(
      context,
      ref,
      ExportRequest.dateRange(range, includeDrafts: _includeDrafts),
    );
    await _refresh();
  }

  Future<void> _selectManually() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CasesListScreen(
          title: 'اختيار حالات للتصدير',
          selectionMode: true,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending = _pending;
    return Scaffold(
      appBar: AppBar(title: const Text('التصدير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.outbox, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'جميع الحالات غير المصدرة',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pending == null
                        ? '…'
                        : '${pending.caseCount} حالة • ${pending.imageCount} صورة '
                              '(تشمل المعدلة بعد آخر تصدير)',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تضمين المسودات'),
                    value: _includeDrafts,
                    onChanged: (v) {
                      setState(() => _includeDrafts = v);
                      _refresh();
                    },
                  ),
                  FilledButton.icon(
                    onPressed: pending == null || pending.caseCount == 0
                        ? null
                        : _exportUnexported,
                    icon: const Icon(Icons.inventory_2),
                    label: const Text('إنشاء حزمة'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(Icons.checklist, size: 30),
              title: const Text('اختيار حالات يدويًا'),
              subtitle: const Text('حدد الحالات من القائمة مع البحث والفلاتر'),
              trailing: const Icon(Icons.chevron_left),
              onTap: _selectManually,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(Icons.date_range, size: 30),
              title: const Text('حالات فترة زمنية'),
              subtitle: Text(
                'مثال: من ${ArabicFormat.date(DateTime(DateTime.now().year, DateTime.now().month))} '
                'إلى ${ArabicFormat.date(DateTime.now())}',
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: _exportRange,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'لتصدير حالة واحدة افتحها ثم اضغط زر التصدير في أعلى الشاشة.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
