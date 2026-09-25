import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
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
          subtitle: 'مراجعة واعتماد',
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
    final today = DateFormat('EEEE d MMMM y', 'ar').format(DateTime.now());

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
