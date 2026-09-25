import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_status_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseStatusRules.exportState', () {
    test('never exported', () {
      expect(
        CaseStatusRules.exportState(revision: 1, lastExportedRevision: null),
        ExportState.notExported,
      );
    });

    test('exported at current revision', () {
      expect(
        CaseStatusRules.exportState(revision: 3, lastExportedRevision: 3),
        ExportState.exported,
      );
    });

    test('any edit after export marks it modified', () {
      expect(
        CaseStatusRules.exportState(revision: 4, lastExportedRevision: 3),
        ExportState.modifiedAfterExport,
      );
    });
  });

  group('CaseStatusRules.displayStatus', () {
    test('review state takes precedence for imported cases', () {
      expect(
        CaseStatusRules.displayStatus(
          status: CaseStatus.ready,
          revision: 2,
          lastExportedRevision: 2,
          reviewState: ReviewState.approved,
        ),
        DisplayStatus.approved,
      );
    });

    test('unexported cases show their lifecycle status', () {
      expect(
        CaseStatusRules.displayStatus(
          status: CaseStatus.draft,
          revision: 1,
          lastExportedRevision: null,
          reviewState: null,
        ),
        DisplayStatus.draft,
      );
    });

    test('edited after export shows the Arabic label', () {
      final status = CaseStatusRules.displayStatus(
        status: CaseStatus.completed,
        revision: 5,
        lastExportedRevision: 4,
        reviewState: null,
      );
      expect(status, DisplayStatus.modifiedAfterExport);
      expect(status.label, 'تم التعديل بعد التصدير');
    });
  });
}
