import 'package:flutter/material.dart';

import '../shared/widgets/phase_placeholder_screen.dart';

/// نقاط الدخول لشاشات الميزات. تُستبدل الشاشات المؤقتة تباعًا مع كل مرحلة.
abstract final class AppRoutes {
  static Future<void> openNewCase(BuildContext context) => _push(
    context,
    const PhasePlaceholderScreen(
      title: 'حالة جديدة',
      icon: Icons.add_circle_outline,
      phase: 3,
    ),
  );

  static Future<void> openSearch(BuildContext context) => _push(
    context,
    const PhasePlaceholderScreen(title: 'البحث', icon: Icons.search, phase: 6),
  );

  static Future<void> openExport(BuildContext context) => _push(
    context,
    const PhasePlaceholderScreen(
      title: 'التصدير',
      icon: Icons.ios_share,
      phase: 7,
    ),
  );

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
