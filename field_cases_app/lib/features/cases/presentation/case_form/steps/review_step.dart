import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';
import '../../../../../core/location/coordinates.dart';
import '../../../../../core/utils/arabic_format.dart';
import '../../../domain/case_form_data.dart';
import '../../../domain/case_form_validator.dart';
import '../../../domain/case_type_field.dart';

/// الخطوة الأخيرة: مراجعة البيانات قبل الحفظ مع الأخطاء إن وجدت.
///
/// تُستبدل بشاشة المعاينة مع النص المولد في المرحلة 5.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({
    super.key,
    required this.data,
    required this.fields,
    required this.errors,
    required this.onGoToStep,
  });

  final CaseFormData data;
  final List<CaseTypeFieldDef> fields;
  final List<CaseValidationError> errors;
  final ValueChanged<CaseFormStep> onGoToStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    Widget labelOf(String? id) {
      if (id == null) return const Text('—');
      return Text(ref.watch(lookupItemProvider(id)).value?.label ?? '…');
    }

    final rows = <(String, Widget)>[
      ('نوع الحالة', labelOf(data.caseTypeId)),
      ('التاريخ والوقت', Text(ArabicFormat.dateTime(data.occurredAt))),
      ('مصدر البلاغ', labelOf(data.reportSourceId)),
      ('المحافظة', labelOf(data.governorateId)),
      if (data.centerId != null) ('المركز', labelOf(data.centerId)),
      if (data.locationText.trim().isNotEmpty)
        ('الموقع', Text(data.locationText.trim())),
      for (final field in fields)
        if (!field.isEmptyValue(data.extraFields[field.fieldKey]))
          (field.label, Text(_formatExtra(data.extraFields[field.fieldKey]))),
      (
        'الإحداثيات',
        Text(
          data.latitude == null || data.longitude == null
              ? '—'
              : Coordinates(data.latitude!, data.longitude!).format(),
          textDirection: TextDirection.ltr,
        ),
      ),
      ('الصور', Text('${data.attachments.length}')),
      (
        'الإصابات',
        Text(data.hasInjuries ? 'نعم (${data.injuriesCount})' : 'لا'),
      ),
      ('الوفيات', Text(data.hasDeaths ? 'نعم (${data.deathsCount})' : 'لا')),
      ('الأضرار', Text(data.hasDamage ? 'نعم' : 'لا')),
      (
        'الجهات المباشرة',
        Text(
          data.partyIds.isEmpty
              ? '—'
              : data.partyIds
                    .map((id) => ref.watch(lookupItemProvider(id)).value?.label)
                    .whereType<String>()
                    .join('، '),
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (errors.isNotEmpty) ...[
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final error in errors)
                    ListTile(
                      leading: Icon(
                        Icons.error_outline,
                        color: scheme.onErrorContainer,
                      ),
                      title: Text(
                        error.message,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                      trailing: TextButton(
                        onPressed: () => onGoToStep(error.step),
                        child: const Text('تعديل'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكن الحفظ كمسودة الآن وإكمال البيانات لاحقًا.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.end,
                            child: value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatExtra(Object? value) {
    return switch (value) {
      true => 'نعم',
      false => 'لا',
      final List<Object?> l => l.join('، '),
      _ => '$value',
    };
  }
}
