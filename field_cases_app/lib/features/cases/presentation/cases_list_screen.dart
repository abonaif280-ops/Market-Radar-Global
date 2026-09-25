import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/utils/arabic_format.dart';
import '../domain/case_views.dart';
import 'widgets/status_chip.dart';

/// الحالات السابقة، الأحدث أولًا ومجمعة باليوم.
///
/// الفلاتر والتحميل التدريجي لآلاف الحالات تُضاف في المرحلة 6.
class CasesListScreen extends ConsumerWidget {
  const CasesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(recentCasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الحالات السابقة')),
      body: cases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر تحميل الحالات: $e')),
        data: (items) =>
            items.isEmpty ? const _EmptyState() : _GroupedList(items: items),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.items});

  final List<CaseListItem> items;

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today
        .difference(DateTime(day.year, day.month, day.day))
        .inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return ArabicFormat.weekdayDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final entries = <Object>[];
    String? currentDay;
    for (final item in items) {
      final day = _dayLabel(item.occurredAt);
      if (day != currentDay) {
        entries.add(day);
        currentDay = day;
      }
      entries.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              entry,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        final item = entry as CaseListItem;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CaseTile(item: item),
        );
      },
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.item});

  final CaseListItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppRoutes.openCaseDetails(context, item.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  ArabicFormat.time24(item.occurredAt),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.caseTypeLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.placeLabel != null)
                      Text(item.placeLabel!, style: textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusChip(item.displayStatus),
                        if (item.imageCount > 0) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.photo_outlined, size: 18),
                          const SizedBox(width: 2),
                          Text('${item.imageCount}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 72, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'لا توجد حالات بعد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'ابدأ بزر "حالة جديدة"',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
