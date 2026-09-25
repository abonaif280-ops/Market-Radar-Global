import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/arabic_format.dart';
import '../domain/case_enums.dart';
import '../domain/case_views.dart';
import 'case_form/case_form_screen.dart';
import 'widgets/status_chip.dart';

/// عرض الحالة مع إمكانية التعديل وتغيير المرحلة.
class CaseDetailsScreen extends ConsumerWidget {
  const CaseDetailsScreen({super.key, required this.caseId});

  final String caseId;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(casesRepositoryProvider).loadForm(caseId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => CaseFormScreen.edit(caseId: caseId, initialData: data),
      ),
    );
  }

  Future<void> _markReady(BuildContext context, WidgetRef ref) async {
    await ref.read(casesRepositoryProvider).setStatus(caseId, CaseStatus.ready);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('أصبحت الحالة جاهزة للإرسال')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(caseDetailsProvider(caseId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الحالة')),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر تحميل الحالة: $e')),
        data: (c) => c == null
            ? const Center(child: Text('الحالة غير موجودة أو محذوفة'))
            : _DetailsBody(details: c),
      ),
      bottomNavigationBar: details.value == null || !details.value!.isEditable
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    if (details.value!.status == CaseStatus.completed) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _markReady(context, ref),
                          child: const Text('جاهزة للإرسال'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _edit(context, ref),
                        icon: const Icon(Icons.edit),
                        label: Text(
                          details.value!.status == CaseStatus.draft
                              ? 'إكمال المسودة'
                              : 'تعديل',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.details});

  final CaseDetails details;

  @override
  Widget build(BuildContext context) {
    final c = details;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final place = [
      c.governorateLabel,
      c.centerLabel,
      c.locationText,
    ].whereType<String>().join(' — ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.caseTypeLabel,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusChip(c.displayStatus),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  c.displayCode,
                  textDirection: TextDirection.ltr,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'رقم تسلسلي ${c.serialNo} • الإصدار ${c.revision}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          rows: [
            ('التاريخ والوقت', ArabicFormat.dateTime(c.occurredAt)),
            ('مصدر البلاغ', c.reportSourceLabel),
            ('المكان', place.isEmpty ? null : place),
            ('وصف الموقع', c.locationDescription),
            if (c.latitude != null && c.longitude != null)
              (
                'الإحداثيات',
                // عزل اتجاه النص حتى يظهر خط العرض أولًا داخل الواجهة العربية.
                '\u2066${c.latitude!.toStringAsFixed(6)}, '
                    '${c.longitude!.toStringAsFixed(6)}\u2069',
              ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          rows: [
            for (final entry in c.extraFields.entries)
              (entry.key, _formatExtra(entry.value)),
            ('معلومات الحالة', c.caseInfo),
            ('الإجراء المتخذ', c.actionTaken),
            ('الإصابات', c.hasInjuries ? 'نعم (${c.injuriesCount})' : 'لا'),
            ('الوفيات', c.hasDeaths ? 'نعم (${c.deathsCount})' : 'لا'),
            (
              'الأضرار',
              c.hasDamage ? 'نعم — ${c.damageDescription ?? ''}' : 'لا',
            ),
            (
              'الجهات المباشرة',
              c.partyLabels.isEmpty ? null : c.partyLabels.join('، '),
            ),
            ('ملاحظات', c.notes),
          ],
        ),
        if (c.finalText != null) ...[
          const SizedBox(height: 12),
          _InfoCard(rows: [('نص الحالة', c.finalText)]),
        ],
        const SizedBox(height: 12),
        _InfoCard(
          rows: [
            ('المدخل', c.enteredBy),
            ('تاريخ الإنشاء', ArabicFormat.dateTime(c.createdAt)),
            ('آخر تعديل', ArabicFormat.dateTime(c.updatedAt)),
          ],
        ),
      ],
    );
  }

  static String _formatExtra(Object? value) {
    return switch (value) {
      true => 'نعم',
      false => 'لا',
      null => '—',
      final List<Object?> l => l.join('، '),
      _ => '$value',
    };
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2 != null && r.$2!.trim().isNotEmpty);
    if (visible.isEmpty) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, value) in visible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: muted, fontSize: 13)),
                    const SizedBox(height: 2),
                    SelectableText(
                      value!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
