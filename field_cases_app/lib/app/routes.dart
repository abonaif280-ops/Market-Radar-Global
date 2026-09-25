import 'package:flutter/material.dart';

import '../features/cases/presentation/case_details_screen.dart';
import '../features/cases/presentation/case_form/case_form_screen.dart';
import '../features/cases/presentation/cases_list_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../shared/widgets/phase_placeholder_screen.dart';

/// نقاط الدخول لشاشات الميزات. تُستبدل الشاشات المؤقتة تباعًا مع كل مرحلة.
abstract final class AppRoutes {
  /// يفتح نموذج حالة جديدة، وبعد الحفظ يعرض تفاصيل الحالة المحفوظة.
  static Future<void> openNewCase(BuildContext context) async {
    final id = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const CaseFormScreen()));
    if (id != null && context.mounted) await openCaseDetails(context, id);
  }

  static Future<void> openCaseDetails(BuildContext context, String caseId) =>
      _push(context, CaseDetailsScreen(caseId: caseId));

  static Future<void> openSearch(BuildContext context) => _push(
    context,
    const CasesListScreen(title: 'البحث', autofocusSearch: true),
  );

  static Future<void> openExport(BuildContext context) =>
      _push(context, const ExportScreen());

  static Future<void> openImport(BuildContext context) => _push(
    context,
    const PhasePlaceholderScreen(
      title: 'استيراد بيانات',
      icon: Icons.download_outlined,
      phase: 11,
    ),
  );

  static Future<void> openInbox(BuildContext context) => _push(
    context,
    const PhasePlaceholderScreen(
      title: 'الدفعات الواردة',
      icon: Icons.inbox_outlined,
      phase: 11,
    ),
  );

  static Future<void> _push(BuildContext context, Widget screen) {
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
