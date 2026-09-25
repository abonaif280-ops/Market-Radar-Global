import '../../features/cases/domain/case_enums.dart';

/// الإجراءات التي تختلف صلاحياتها بين الموظف والمشرف (docs/DESIGN.md البند 15).
enum AppAction {
  createCase,
  editOwnCase,
  exportCases,
  importPackages,
  viewInbox,
  reviewCases,
  viewAllCases,
  viewAuditLog,
}

/// نقطة واحدة لقرار الصلاحيات بدل الشروط المتفرقة في الواجهة.
abstract final class Permissions {
  static const Set<AppAction> _supervisorOnly = {
    AppAction.importPackages,
    AppAction.viewInbox,
    AppAction.reviewCases,
    AppAction.viewAllCases,
    AppAction.viewAuditLog,
  };

  static bool can(UserRole role, AppAction action) =>
      role == UserRole.supervisor || !_supervisorOnly.contains(action);
}
