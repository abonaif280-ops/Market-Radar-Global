import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/cases/domain/case_enums.dart';
import '../../features/templates/domain/default_templates.dart';
import 'seed_data.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LookupItems,
    Cases,
    Attachments,
    CaseParties,
    CaseTypeFields,
    TextTemplates,
    CaseVersions,
    ExportBatches,
    ExportBatchItems,
    ImportBatches,
    ImportBatchItems,
    AuditLog,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// قاعدة البيانات داخل مجلد التطبيق الخاص (Application Support).
  factory AppDatabase.open() {
    return AppDatabase(
      driftDatabase(
        name: 'field_cases',
        native: const DriftNativeOptions(
          databaseDirectory: getApplicationSupportDirectory,
        ),
      ),
    );
  }

  /// الإصدار 2: لا تغيير في الجداول؛ يضيف القوالب الافتراضية للقواعد المنشأة بالإصدار 1.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaults();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await seedDefaults();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// يُدرج القوائم والحقول الأولية دون المساس بما عدّله المستخدم.
  Future<void> seedDefaults() async {
    await transaction(() async {
      for (final item in SeedData.lookups) {
        await into(lookupItems).insert(
          LookupItemsCompanion.insert(
            id: item.id,
            listKey: item.listKey,
            code: item.code,
            label: item.label,
            parentId: Value(
              item.parentCode == null
                  ? null
                  : lookupId(LookupKeys.governorate, item.parentCode!),
            ),
            sortOrder: Value(SeedData.lookups.indexOf(item)),
            isSystem: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final field in SeedData.fields) {
        await into(caseTypeFields).insert(
          CaseTypeFieldsCompanion.insert(
            id: field.id,
            caseTypeId: field.caseTypeId,
            fieldKey: field.fieldKey,
            label: field.label,
            inputType: field.inputType,
            optionsJson: Value(
              field.options == null ? null : jsonEncode(field.options),
            ),
            isRequired: Value(field.isRequired),
            sortOrder: Value(SeedData.fields.indexOf(field)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      final now = DateTime.now().toUtc();
      for (final entry in DefaultTemplates.byCaseType.entries) {
        final code = entry.key;
        await into(textTemplates).insert(
          TextTemplatesCompanion.insert(
            id: code == null
                ? DefaultTemplates.genericId
                : DefaultTemplates.idFor(code),
            caseTypeId: Value(
              code == null ? null : lookupId(LookupKeys.caseType, code),
            ),
            name: entry.value.$1,
            body: entry.value.$2,
            isDefault: const Value(true),
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
