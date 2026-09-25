import 'case_enums.dart';

/// قواعد اشتقاق حالة التصدير والحالة الظاهرة.
///
/// حالة التصدير لا تُخزَّن كعمود مستقل حتى لا تتعارض مع revision:
/// أي تعديل محفوظ يزيد revision، فتصبح الحالة تلقائيًا "معدلة بعد التصدير".
class CaseStatusRules {
  const CaseStatusRules._();

  static ExportState exportState({
    required int revision,
    required int? lastExportedRevision,
  }) {
    if (lastExportedRevision == null) return ExportState.notExported;
    if (lastExportedRevision >= revision) return ExportState.exported;
    return ExportState.modifiedAfterExport;
  }

  static DisplayStatus displayStatus({
    required CaseStatus status,
    required int revision,
    required int? lastExportedRevision,
    required ReviewState? reviewState,
  }) {
    switch (reviewState) {
      case ReviewState.incoming:
        return DisplayStatus.imported;
      case ReviewState.underReview:
        return DisplayStatus.underReview;
      case ReviewState.approved:
        return DisplayStatus.approved;
      case ReviewState.rejected:
        return DisplayStatus.rejected;
      case null:
        break;
    }

    switch (exportState(
      revision: revision,
      lastExportedRevision: lastExportedRevision,
    )) {
      case ExportState.exported:
        return DisplayStatus.exported;
      case ExportState.modifiedAfterExport:
        return DisplayStatus.modifiedAfterExport;
      case ExportState.notExported:
        return switch (status) {
          CaseStatus.draft => DisplayStatus.draft,
          CaseStatus.completed => DisplayStatus.completed,
          CaseStatus.ready => DisplayStatus.ready,
        };
    }
  }
}
