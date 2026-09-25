import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../packages/domain/case_diff.dart';
import '../data/version_resolution_service.dart';

/// "توجد نسخة أحدث من هذه الحالة": مقارنة الحالية بالواردة واتخاذ القرار.
class VersionCompareScreen extends ConsumerStatefulWidget {
  const VersionCompareScreen({
    super.key,
    required this.batchId,
    required this.caseId,
  });

  final String batchId;
  final String caseId;

  @override
  ConsumerState<VersionCompareScreen> createState() =>
      _VersionCompareScreenState();
}

class _VersionCompareScreenState extends ConsumerState<VersionCompareScreen> {
  late Future<VersionComparison> _comparison = _load();
  bool _onlyChanged = true;
  bool _busy = false;

  Future<VersionComparison> _load() => ref
      .read(versionResolutionProvider)
      .compare(widget.batchId, widget.caseId);

  Future<void> _decide(VersionChoice choice) async {
    final (title, body) = switch (choice) {
      VersionChoice.keepCurrent => (
        'الاحتفاظ بالنسخة الحالية؟',
        'ستُتجاهل النسخة الواردة.',
      ),
      VersionChoice.replace => (
        'الاستبدال بالنسخة الجديدة؟',
        'ستحل النسخة الواردة محل الحالية، وتُحفظ الحالية في سجل الإصدارات. '
            'ستعود الحالة للمراجعة.',
      ),
      VersionChoice.keepBoth => (
        'الاحتفاظ بالنسختين؟',
        'تبقى الحالية كما هي، وتُحفظ الواردة في سجل الإصدارات للرجوع إليها.',
      ),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(versionResolutionProvider)
          .resolve(widget.batchId, widget.caseId, choice);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('حُفظ القرار')));
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذر تنفيذ القرار: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسخة أحدث من الحالة')),
      body: FutureBuilder<VersionComparison>(
        future: _comparison,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(() => _comparison = _load()),
            );
          }
          return _ComparisonView(
            comparison: snap.data!,
            onlyChanged: _onlyChanged,
            onToggle: (v) => setState(() => _onlyChanged = v),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _busy
              ? const LinearProgressIndicator()
              : FutureBuilder<VersionComparison>(
                  future: _comparison,
                  builder: (context, snap) {
                    final canUseIncoming = snap.hasData;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: canUseIncoming
                              ? () => _decide(VersionChoice.replace)
                              : null,
                          icon: const Icon(Icons.published_with_changes),
                          label: const Text('الاستبدال بالنسخة الجديدة'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _decide(VersionChoice.keepCurrent),
                                child: const Text('الاحتفاظ بالحالية'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: canUseIncoming
                                    ? () => _decide(VersionChoice.keepBoth)
                                    : null,
                                child: const Text('الاحتفاظ بالنسختين'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({
    required this.comparison,
    required this.onlyChanged,
    required this.onToggle,
  });

  final VersionComparison comparison;
  final bool onlyChanged;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = comparison;
    final rows = onlyChanged ? c.changedFields : c.fields;
    final photos = c.attachments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'توجد نسخة أحدث من هذه الحالة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${c.current.displayCode}\n'
                  'الحالية: الإصدار ${c.current.revision}  ←  '
                  'الواردة: الإصدار ${c.incoming.revision}\n'
                  'عدد الحقول المختلفة: ${c.changedFields.length}',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ],
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('عرض الحقول المختلفة فقط'),
          value: onlyChanged,
          onChanged: onToggle,
        ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('لا فروق في البيانات النصية.'),
          ),
        for (final field in rows) ...[
          _FieldRow(field: field),
          const SizedBox(height: 8),
        ],
        if (photos.hasChanges || !onlyChanged) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الصور',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text('دون تغيير: ${photos.unchanged}'),
                  if (photos.added.isNotEmpty)
                    Text(
                      'مضافة في الواردة (${photos.added.length}): '
                      '${photos.added.map((a) => a.fileName).join('، ')}',
                      style: TextStyle(color: scheme.primary),
                    ),
                  if (photos.removed.isNotEmpty)
                    Text(
                      'محذوفة في الواردة (${photos.removed.length}): '
                      '${photos.removed.map((a) => a.fileName).join('، ')}',
                      style: TextStyle(color: scheme.error),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final FieldDiff field;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget box(String title, String value, Color? color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color ?? scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(value),
          ],
        ),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    field.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (field.changed)
                  Icon(Icons.change_circle, size: 18, color: scheme.tertiary),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box('الحالية', field.current, null),
                const SizedBox(width: 8),
                box(
                  'الواردة',
                  field.incoming,
                  field.changed ? scheme.tertiaryContainer : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
