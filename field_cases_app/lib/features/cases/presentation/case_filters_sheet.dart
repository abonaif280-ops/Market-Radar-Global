import 'package:flutter/material.dart';

import '../../../core/db/seed_data.dart';
import '../../../core/utils/arabic_format.dart';
import '../domain/case_query.dart';
import 'widgets/lookup_dropdown.dart';

/// الفلاتر المتقدمة: نوع الحالة، المحافظة، مصدر البلاغ، فترة زمنية.
class CaseFiltersSheet extends StatefulWidget {
  const CaseFiltersSheet({super.key, required this.initial});

  final CaseQuery initial;

  static Future<CaseQuery?> show(BuildContext context, CaseQuery initial) {
    return showModalBottomSheet<CaseQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CaseFiltersSheet(initial: initial),
    );
  }

  @override
  State<CaseFiltersSheet> createState() => _CaseFiltersSheetState();
}

class _CaseFiltersSheetState extends State<CaseFiltersSheet> {
  late CaseQuery _query = widget.initial;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange:
          _query.datePreset == DatePreset.custom &&
              _query.customFrom != null &&
              _query.customTo != null
          ? DateTimeRange(start: _query.customFrom!, end: _query.customTo!)
          : null,
    );
    if (picked == null) return;
    setState(
      () => _query = _query.copyWith(
        datePreset: DatePreset.custom,
        customFrom: picked.start,
        customTo: picked.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRange =
        _query.datePreset == DatePreset.custom && _query.customFrom != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الفلاتر',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LookupDropdown(
              listKey: LookupKeys.caseType,
              label: 'نوع الحالة',
              icon: Icons.category_outlined,
              allowClear: true,
              value: _query.caseTypeId,
              onChanged: (id) =>
                  setState(() => _query = _query.copyWith(caseTypeId: id)),
            ),
            const SizedBox(height: 12),
            LookupDropdown(
              listKey: LookupKeys.governorate,
              label: 'المحافظة',
              icon: Icons.location_city,
              allowClear: true,
              value: _query.governorateId,
              onChanged: (id) =>
                  setState(() => _query = _query.copyWith(governorateId: id)),
            ),
            const SizedBox(height: 12),
            LookupDropdown(
              listKey: LookupKeys.reportSource,
              label: 'مصدر البلاغ',
              icon: Icons.call_received,
              allowClear: true,
              value: _query.reportSourceId,
              onChanged: (id) =>
                  setState(() => _query = _query.copyWith(reportSourceId: id)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                hasRange
                    ? 'من ${ArabicFormat.date(_query.customFrom!)} إلى ${ArabicFormat.date(_query.customTo ?? DateTime.now())}'
                    : 'فترة زمنية محددة',
              ),
            ),
            if (hasRange)
              TextButton(
                onPressed: () => setState(
                  () => _query = _query.copyWith(
                    datePreset: DatePreset.any,
                    customFrom: null,
                    customTo: null,
                  ),
                ),
                child: const Text('إلغاء الفترة'),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(CaseQuery(text: _query.text)),
                    child: const Text('مسح الكل'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_query),
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
