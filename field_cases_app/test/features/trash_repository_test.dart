import 'dart:io';

import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:field_cases/features/trash/data/trash_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_device.dart';

void main() {
  late Directory tmp;
  late TestDevice device;
  late TrashRepository trash;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('trash');
    device = TestDevice(tmp, 'مركز');
    await device.init();
    trash = TrashRepository(
      device.db,
      settings: device.settings,
      audit: device.audit,
      storage: device.storage,
      clock: () => TestDevice.now,
    );
  });
  tearDown(() async {
    await device.db.close();
    await tmp.delete(recursive: true);
  });

  Future<List<File>> photosOf(String caseId) async {
    final rows = await (device.db.select(
      device.db.attachments,
    )..where((a) => a.caseId.equals(caseId))).get();
    return [
      for (final a in rows) File(device.storage.absolute(a.relativePath)),
    ];
  }

  test(
    'soft delete hides the case everywhere and restore brings it back',
    () async {
      final id = await device.addCase(photos: 2);
      final keep = await device.addCase();

      await trash.softDelete(id);
      expect(await device.cases.countCases(const CaseQuery()), 1);
      expect(await device.cases.countCases(const CaseQuery(text: 'الرايس')), 1);
      final deleted = await trash.watchDeleted().first;
      expect(deleted.single.id, id);
      expect(deleted.single.photoCount, 2);
      expect(await trash.watchCount().first, 1);
      // الملفات باقية حتى الحذف النهائي.
      for (final f in await photosOf(id)) {
        expect(f.existsSync(), isTrue);
      }

      await trash.restore(id);
      expect(await device.cases.countCases(const CaseQuery()), 2);
      expect(await device.cases.countCases(const CaseQuery(text: 'الرايس')), 2);
      expect(await trash.watchDeleted().first, isEmpty);
      expect(keep, isNotEmpty);
    },
  );

  test('purge removes rows and files and only works from the trash', () async {
    final id = await device.addCase(photos: 2);
    final files = await photosOf(id);

    // حالة غير محذوفة لا تُحذف نهائيًا مباشرة.
    expect((await trash.purge(id)).cases, 0);
    expect(await device.cases.byId(id), isNotNull);

    await trash.softDelete(id);
    final result = await trash.purge(id);
    expect(result.cases, 1);
    expect(result.files, greaterThanOrEqualTo(2));
    expect(await device.cases.byId(id), isNull);
    for (final f in files) {
      expect(f.existsSync(), isFalse);
    }
    expect(
      Directory(p.join(device.storage.root.path, 'attachments', id))
          .existsSync(),
      isFalse,
    );
  });

  test('purge works for exported cases and keeps the export batch', () async {
    final id = await device.addCase(photos: 1);
    await device.exporter.export(ExportRequest.single(id));
    await trash.softDelete(id);
    await trash.purge(id);
    expect(await device.db.select(device.db.exportBatches).get(), hasLength(1));
    expect(await device.db.select(device.db.exportBatchItems).get(), isEmpty);
  });

  test('empty trash purges all deleted cases and audits every step', () async {
    final a = await device.addCase(photos: 1);
    final b = await device.addCase();
    await device.addCase();
    await trash.softDelete(a);
    await trash.softDelete(b);

    final result = await trash.purgeAll();
    expect(result.cases, 2);
    expect(await device.cases.countCases(const CaseQuery()), 1);

    final actions = (await device.audit.recent()).map((e) => e.action).toList();
    expect(actions.where((x) => x == AuditActions.caseDeleted), hasLength(2));
    expect(actions.where((x) => x == AuditActions.casePurged), hasLength(2));
  });
}
