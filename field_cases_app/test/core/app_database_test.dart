import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/audit_logger.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/settings/data/lookup_repository.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

CasesCompanion _case(String id, DateTime occurredAt, {DateTime? deletedAt}) {
  final now = DateTime.now().toUtc();
  return CasesCompanion.insert(
    id: id,
    displayCode: 'EVT-20260925-${id.substring(0, 6).toUpperCase()}',
    serialNo: 1,
    caseTypeId: lookupId(LookupKeys.caseType, 'SOLID_OBJECT'),
    occurredAt: occurredAt.toUtc(),
    originDeviceId: 'DEV-TEST01',
    status: CaseStatus.draft,
    createdAt: now,
    updatedAt: now,
    deletedAt: Value(deletedAt),
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = _memoryDb());
  tearDown(() => db.close());

  group('seed data', () {
    test('seeds the default case types in order', () async {
      final types = await LookupRepository(db).activeItems(LookupKeys.caseType);
      expect(types.map((t) => t.label), [
        'جسم صلب',
        'شظايا',
        'طائرة مسيرة',
        'حريق',
        'حالة أمنية',
        'حادث أمني',
        'أخرى',
      ]);
    });

    test('seeding twice does not duplicate or overwrite edits', () async {
      final repo = LookupRepository(db);
      final fireId = lookupId(LookupKeys.caseType, 'FIRE');
      await repo.rename(fireId, 'حريق (معدل)');

      await db.seedDefaults();

      final types = await repo.activeItems(LookupKeys.caseType);
      expect(
        types,
        hasLength(
          SeedData.lookups
              .where((l) => l.listKey == LookupKeys.caseType)
              .length,
        ),
      );
      expect((await repo.byId(fireId))!.label, 'حريق (معدل)');
    });

    test('centers are linked to their governorate', () async {
      final centers = await LookupRepository(db).activeItems(
        LookupKeys.center,
        parentId: lookupId(LookupKeys.governorate, 'BADR'),
      );
      expect(centers.single.label, 'مركز الرايس');
    });

    test('seeds dynamic fields for the solid object type', () async {
      final fields =
          await (db.select(db.caseTypeFields)..where(
                (f) => f.caseTypeId.equals(
                  lookupId(LookupKeys.caseType, 'SOLID_OBJECT'),
                ),
              ))
              .get();
      expect(fields.map((f) => f.fieldKey), containsAll(['has_fire']));
    });
  });

  group('LookupRepository', () {
    test('added items go last and deactivated items are hidden', () async {
      final repo = LookupRepository(db);
      final id = await repo.add(
        listKey: LookupKeys.reportSource,
        label: ' بلاغ هاتفي ',
      );
      var sources = await repo.activeItems(LookupKeys.reportSource);
      expect(sources.last.id, id);
      expect(sources.last.label, 'بلاغ هاتفي');

      await repo.setActive(id, active: false);
      sources = await repo.activeItems(LookupKeys.reportSource);
      expect(sources.map((s) => s.id), isNot(contains(id)));
    });
  });

  group('SettingsRepository', () {
    test('device id is generated once and kept', () async {
      final repo = SettingsRepository(db);
      final first = await repo.deviceId();
      final second = await repo.deviceId();
      expect(first, matches(RegExp(r'^DEV-[0-9A-F]{6}$')));
      expect(second, first);
    });

    test('serial numbers increase sequentially', () async {
      final repo = SettingsRepository(db);
      expect(await repo.nextSerialNo(), 1);
      expect(await repo.nextSerialNo(), 2);
      expect(await repo.nextSerialNo(), 3);
    });

    test('role defaults to employee and can be changed', () async {
      final repo = SettingsRepository(db);
      expect(await repo.watchRole().first, UserRole.employee);
      await repo.setRole(UserRole.supervisor);
      expect(await repo.watchRole().first, UserRole.supervisor);
    });
  });

  group('CasesRepository', () {
    test('today count ignores other days and soft-deleted cases', () async {
      final now = DateTime(2026, 9, 25, 14, 35);
      await db.into(db.cases).insert(_case('aaaaaa01', now));
      await db
          .into(db.cases)
          .insert(_case('bbbbbb02', now.subtract(const Duration(days: 1))));
      await db
          .into(db.cases)
          .insert(_case('cccccc03', now, deletedAt: DateTime.now().toUtc()));

      final repo = CasesRepository(
        db,
        settings: SettingsRepository(db),
        audit: AuditLogger(db),
        storage: AttachmentStorage(Directory.systemTemp),
        clock: () => now,
      );
      expect(await repo.watchTodayCount().first, 1);
    });

    test('foreign keys are enforced', () async {
      final bad = _case(
        'dddddd04',
        DateTime.now(),
      ).copyWith(caseTypeId: const Value('case_type:MISSING'));
      expect(() => db.into(db.cases).insert(bad), throwsA(anything));
    });
  });

  group('AuditLogger', () {
    test('records actions newest first', () async {
      final logger = AuditLogger(db);
      await logger.log(
        action: AuditActions.caseCreated,
        entityType: 'case',
        entityId: 'x1',
      );
      await logger.log(
        action: AuditActions.caseUpdated,
        entityType: 'case',
        entityId: 'x1',
        details: {'revision': 2},
      );
      final entries = await logger.recent();
      expect(entries.first.action, AuditActions.caseUpdated);
      expect(entries.first.detailsJson, '{"revision":2}');
      expect(entries.last.action, AuditActions.caseCreated);
    });
  });
}
