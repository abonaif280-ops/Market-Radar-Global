import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/utils/arabic_format.dart';
import '../../../shared/widgets/big_action_card.dart';
import '../../cases/domain/case_enums.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenCases});

  /// الانتقال إلى تبويب "الحالات السابقة" في شريط التنقل السفلي.
  final VoidCallback onOpenCases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSupervisor =
        ref.watch(userRoleProvider).value == UserRole.supervisor;
    final pendingReview = isSupervisor
        ? ref.watch(pendingReviewCountProvider).value ?? 0
        : 0;

    final actions = <BigActionCard>[
      BigActionCard(
        icon: Icons.add_circle,
        title: 'حالة جديدة',
        subtitle: 'تسجيل حالة ميدانية',
        highlighted: true,
        onTap: () => AppRoutes.openNewCase(context),
      ),
      BigActionCard(
        icon: Icons.history,
        title: 'الحالات السابقة',
        subtitle: 'الأحدث أولًا',
        onTap: onOpenCases,
      ),
      BigActionCard(
        icon: Icons.search,
        title: 'البحث',
        subtitle: 'برقم الحالة أو كلمة',
        onTap: () => AppRoutes.openSearch(context),
      ),
      BigActionCard(
        icon: Icons.ios_share,
        title: 'التصدير',
        subtitle: 'حزمة حالات وصور',
        onTap: () => AppRoutes.openExport(context),
      ),
      if (isSupervisor) ...[
        BigActionCard(
          icon: Icons.download,
          title: 'استيراد بيانات',
          subtitle: 'ملف ‎.casepkg',
          onTap: () => AppRoutes.openImport(context),
        ),
        BigActionCard(
          icon: Icons.inbox,
          title: 'الدفعات الواردة',
          subtitle: pendingReview > 0
              ? '$pendingReview حالة للمراجعة'
              : 'مراجعة واعتماد',
          onTap: () => AppRoutes.openInbox(context),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الحالات الميدانية')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const _TodaySummaryCard(),
          if (isSupervisor) ...[
            const SizedBox(height: 12),
            const _SupervisorTodayCard(),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends ConsumerWidget {
  const _TodaySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final orgName = ref.watch(orgNameProvider).value;
    final role = ref.watch(userRoleProvider).value ?? UserRole.employee;
    final todayCount = ref.watch(todayCasesCountProvider).value ?? 0;
    final today = ArabicFormat.weekdayDate(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (orgName == null || orgName.isEmpty)
                        ? 'لم تُحدد الجهة بعد'
                        : orgName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(today, style: textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      role == UserRole.supervisor
                          ? Icons.verified_user
                          : Icons.person,
                      size: 18,
                    ),
                    label: Text(role == UserRole.supervisor ? 'مشرف' : 'موظف'),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$todayCount',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                Text('حالات اليوم', style: textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// لوحة المشرف: إجمالي حالات اليوم حسب الجهة ونوع الحالة.
class _SupervisorTodayCard extends ConsumerWidget {
  const _SupervisorTodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todayStatsProvider).value;
    if (stats == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget group(String title, Map<String, int> values) {
      final sorted = values.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in sorted)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${e.key}: ${e.value}'),
                ),
            ],
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إجمالي الحالات اليوم: ${stats.total}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (stats.pendingReview > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.tertiaryContainer,
                    side: BorderSide.none,
                    label: Text('${stats.pendingReview} للمراجعة'),
                  ),
              ],
            ),
            if (stats.total > 0) ...[
              const SizedBox(height: 12),
              group('حسب الجهة', stats.byOrg),
              const SizedBox(height: 10),
              group('حسب نوع الحالة', stats.byType),
            ],
          ],
        ),
      ),
    );
  }
}
