import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';
import '../../../../../core/db/seed_data.dart';
import '../../../domain/case_form_data.dart';
import '../../../domain/case_type_field.dart';
import '../../widgets/dynamic_field_input.dart';
import '../../widgets/yes_no_count_tile.dart';

/// الخطوة 3: تفاصيل خاصة بالنوع + الإصابات والأضرار + الجهات المباشرة.
class DetailsStep extends ConsumerWidget {
  const DetailsStep({
    super.key,
    required this.data,
    required this.fields,
    required this.onChanged,
  });

  final CaseFormData data;
  final List<CaseTypeFieldDef> fields;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parties =
        ref
            .watch(
              activeLookupProvider((listKey: LookupKeys.party, parentId: null)),
            )
            .value ??
        const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fields.isNotEmpty) ...[
          const _Section('تفاصيل النوع'),
          for (final field in fields) ...[
            DynamicFieldInput(
              key: ValueKey('${data.caseTypeId}|${field.fieldKey}'),
              field: field,
              value: data.extraFields[field.fieldKey],
              onChanged: (value) {
                data.extraFields[field.fieldKey] = value;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
        const _Section('معلومات الحالة'),
        TextFormField(
          initialValue: data.caseInfo,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'معلومات الحالة'),
          onChanged: (v) => data.caseInfo = v,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: data.actionTaken,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'الإجراء المتخذ'),
          onChanged: (v) => data.actionTaken = v,
        ),
        const SizedBox(height: 20),
        const _Section('الإصابات والأضرار'),
        Card(
          child: Column(
            children: [
              YesNoCountTile(
                icon: Icons.personal_injury_outlined,
                title: 'وجود إصابات',
                value: data.hasInjuries,
                count: data.injuriesCount,
                onChanged: (on) {
                  data.hasInjuries = on;
                  if (on && data.injuriesCount < 1) data.injuriesCount = 1;
                  onChanged();
                },
                onCountChanged: (n) {
                  data.injuriesCount = n;
                  onChanged();
                },
              ),
              const Divider(height: 1),
              YesNoCountTile(
                icon: Icons.heart_broken_outlined,
                title: 'وجود وفيات',
                value: data.hasDeaths,
                count: data.deathsCount,
                onChanged: (on) {
                  data.hasDeaths = on;
                  if (on && data.deathsCount < 1) data.deathsCount = 1;
                  onChanged();
                },
                onCountChanged: (n) {
                  data.deathsCount = n;
                  onChanged();
                },
              ),
              const Divider(height: 1),
              YesNoCountTile(
                icon: Icons.domain_disabled_outlined,
                title: 'وجود أضرار',
                value: data.hasDamage,
                onChanged: (on) {
                  data.hasDamage = on;
                  onChanged();
                },
              ),
              if (data.hasDamage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextFormField(
                    initialValue: data.damageDescription,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'وصف الأضرار *',
                    ),
                    onChanged: (v) => data.damageDescription = v,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Section('الجهات التي تمت مباشرتها'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final party in parties)
              FilterChip(
                label: Text(party.label),
                selected: data.partyIds.contains(party.id),
                onSelected: (on) {
                  on
                      ? data.partyIds.add(party.id)
                      : data.partyIds.remove(party.id);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: data.notes,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'ملاحظات'),
          onChanged: (v) => data.notes = v,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
