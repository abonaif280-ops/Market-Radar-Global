import 'dart:io';

import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:field_cases/features/import/data/version_resolution_service.dart';
import 'package:field_cases/features/packages/domain/case_diff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../helpers/test_device.dart';

void main() {
  late Directory temp;
  late TestDevice employee;
  late TestDevice supervisor;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('versions_test');
    employee = TestDevice(Directory(p.join(temp.path, 'e')), 'شرطة ينبع');
    supervisor = TestDevice(Directory(p.join(temp.path, 's')), 'إدارة المنطقة');
    await employee.init();
    await supervisor.init();
  });
  tearDown(() async {
    await employee.db.close();
    await supervisor.db.close();
    await temp.delete(recursive: true);
  });

  /// الموظف يرسل حالة، المشرف يعتمدها، ثم يعدّلها الموظف ويرسلها ثانية.
  Future<(String caseId, String batchId)> sendEditedCase({
    bool addPhoto = false,
    bool removePhoto = false,
  }) async {
    final id = await employee.addCase(photos: 2);
    final first = await employee.exporter.export(
      const ExportRequest.unexported(),
    );
    await supervisor.importer.commit(
      await supervisor.importer.prepare(first.file.path),
    );
    await supervisor.inbox.approve([id]);

    final form = await employee.cases.loadForm(id)
      ..notes = 'تحديث: وصول الدفاع المدني'
      ..hasInjuries = true
      ..injuriesCount = 1
      ..partyIds.add(lookupId(LookupKeys.party, 'CIVIL_DEF'));
    if (removePhoto) form.attachments.removeAt(0);
    if (addPhoto) {
      // صورة مختلفة فعلًا (بصمة جديدة) عن صور الحالة.
      final file = File(p.join(temp.path, 'extra.jpg'));
      await file.writeAsBytes(
        img.encodeJpg(
          img.Image(width: 50, height: 50)..clear(img.ColorRgb8(200, 10, 90)),
        ),
      );
      form.attachments.add(await employee.storage.stageImage(file.path));
    }
    await employee.cases.updateCase(id, form, status: CaseStatus.completed);
    final second = await employee.exporter.export(ExportRequest.single(id));
    final report = await supervisor.importer.prepare(second.file.path);
    await supervisor.importer.commit(report);
    return (id, second.manifest.packageId);
  }

  test('pending newer version is listed with both revisions', () async {
    final (id, batch) = await sendEditedCase();
    final pending = await supervisor.versions.watchPending().first;
    expect(pending.single.caseId, id);
    expect(pending.single.batchId, batch);
    expect(pending.single.currentRevision, 1);
    expect(pending.single.incomingRevision, 2);
    expect(pending.single.batchTitle, 'شرطة ينبع');

    final batches = await supervisor.inbox.watchBatches().first;
    expect(batches.firstWhere((b) => b.id == batch).pendingDecisionCount, 1);
  });

  test('comparison shows changed fields and photo differences', () async {
    final (id, batch) = await sendEditedCase(addPhoto: true, removePhoto: true);
    final cmp = await supervisor.versions.compare(batch, id);

    final changed = {for (final f in cmp.changedFields) f.label: f};
    expect(
      changed.keys,
      containsAll(['الإصابات', 'الجهات المباشرة', 'ملاحظات']),
    );
    expect(changed['الإصابات']!.current, 'لا');
    expect(changed['الإصابات']!.incoming, 'نعم (1)');
    expect(changed['ملاحظات']!.incoming, 'تحديث: وصول الدفاع المدني');
    expect(changed.containsKey('نوع الحالة'), isFalse);

    expect(cmp.attachments.added, hasLength(1));
    expect(cmp.attachments.removed, hasLength(1));
    expect(cmp.attachments.unchanged, 1);
    expect(cmp.current.revision, 1);
    expect(cmp.incoming.revision, 2);
  });

  test('keep current: nothing changes and the package is cleaned up', () async {
    final (id, batch) = await sendEditedCase();
    await supervisor.versions.resolve(batch, id, VersionChoice.keepCurrent);

    final row = (await supervisor.cases.byId(id))!;
    expect(row.revision, 1);
    expect(row.reviewState, ReviewState.approved);
    expect(await supervisor.versions.watchPending().first, isEmpty);
    expect(supervisor.versions.packageFileFor(batch).existsSync(), isFalse);
    expect(await supervisor.versions.watchVersions(id).first, isEmpty);
  });

  test(
    'replace: incoming becomes current, old version archived, photos synced',
    () async {
      final (id, batch) = await sendEditedCase(
        addPhoto: true,
        removePhoto: true,
      );
      final before = (await supervisor.cases.loadForm(id)).attachments;

      await supervisor.versions.resolve(batch, id, VersionChoice.replace);

      final row = (await supervisor.cases.byId(id))!;
      final employeeRow = (await employee.cases.byId(id))!;
      expect(row.revision, 2);
      expect(row.contentHash, employeeRow.contentHash);
      expect(row.notes, 'تحديث: وصول الدفاع المدني');
      // المحتوى تغيّر فيعود للمراجعة ضمن الدفعة الجديدة.
      expect(row.reviewState, ReviewState.incoming);
      expect(row.sourceBatchId, batch);

      final details = (await supervisor.cases.watchDetails(id).first)!;
      expect(
        details.partyLabels,
        containsAll(['الدفاع المدني', 'إدارة الأسلحة والمتفجرات']),
      );
      expect(details.attachments, hasLength(2));
      expect(
        details.attachments.map((a) => a.sha256),
        isNot(contains(before.first.sha256)),
      );
      for (final a in details.attachments) {
        expect(File(a.filePath).existsSync(), isTrue);
      }

      final versions = await supervisor.versions.watchVersions(id).first;
      expect(versions.single.revision, 1);
      expect(versions.single.source, VersionSource.local);
      expect(versions.single.snapshot.notes, isNull);

      // البحث يعكس المحتوى الجديد.
      final found = await supervisor.cases.searchCases(
        const CaseQuery(text: 'وصول'),
      );
      expect(found.items.single.id, id);

      final actions = (await supervisor.audit.recent()).map((e) => e.action);
      expect(actions, contains(VersionResolutionService.versionReplaced));
      expect(supervisor.versions.packageFileFor(batch).existsSync(), isFalse);
    },
  );

  test('keep both: current stays, incoming saved as a version', () async {
    final (id, batch) = await sendEditedCase();
    await supervisor.versions.resolve(batch, id, VersionChoice.keepBoth);

    final row = (await supervisor.cases.byId(id))!;
    expect(row.revision, 1);
    final versions = await supervisor.versions.watchVersions(id).first;
    expect(versions.single.revision, 2);
    expect(versions.single.source, VersionSource.import);
    expect(versions.single.snapshot.notes, 'تحديث: وصول الدفاع المدني');
    expect(versions.single.sourceLabel, 'نسخة واردة محفوظة');
  });

  test('a decision can only be made once', () async {
    final (id, batch) = await sendEditedCase();
    await supervisor.versions.resolve(batch, id, VersionChoice.keepCurrent);
    expect(
      () => supervisor.versions.resolve(batch, id, VersionChoice.replace),
      throwsA(isA<VersionResolutionException>()),
    );
  });

  test(
    'missing package: comparison explains, keeping current still works',
    () async {
      final (id, batch) = await sendEditedCase();
      await supervisor.versions.packageFileFor(batch).delete();

      expect(
        () => supervisor.versions.compare(batch, id),
        throwsA(isA<VersionResolutionException>()),
      );
      await supervisor.versions.resolve(batch, id, VersionChoice.keepCurrent);
      expect(await supervisor.versions.watchPending().first, isEmpty);
    },
  );

  test('field diff helper', () async {
    final (id, batch) = await sendEditedCase();
    final cmp = await supervisor.versions.compare(batch, id);
    final same = CaseDiff.fields(cmp.current, cmp.current);
    expect(same.where((f) => f.changed), isEmpty);
    expect(CaseDiff.attachments(cmp.current, cmp.current).hasChanges, isFalse);
    expect(AuditActions.caseApproved, isNotEmpty);
  });
}
