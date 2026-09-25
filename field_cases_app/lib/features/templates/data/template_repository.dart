import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/seed_data.dart';
import '../domain/default_templates.dart';

/// قالب مع اسم نوع الحالة (لشاشة إدارة القوالب).
class TemplateListItem {
  const TemplateListItem({required this.template, required this.caseTypeLabel});

  final TextTemplate template;

  /// null للقالب العام.
  final String? caseTypeLabel;
}

class TemplateRepository {
  TemplateRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// القالب المستخدم لنوع الحالة: الخاص به إن وجد، وإلا القالب العام.
  Future<TextTemplate?> templateFor(String? caseTypeId) async {
    if (caseTypeId != null) {
      final specific =
          await (_db.select(_db.textTemplates)
                ..where(
                  (t) =>
                      t.caseTypeId.equals(caseTypeId) & t.isActive.equals(true),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.isDefault)])
                ..limit(1))
              .getSingleOrNull();
      if (specific != null) return specific;
    }
    return (_db.select(
      _db.textTemplates,
    )..where((t) => t.id.equals(DefaultTemplates.genericId))).getSingleOrNull();
  }

  Stream<List<TemplateListItem>> watchAll() {
    final query =
        _db.select(_db.textTemplates).join([
          leftOuterJoin(
            _db.lookupItems,
            _db.lookupItems.id.equalsExp(_db.textTemplates.caseTypeId),
          ),
        ])..orderBy([
          // القالب العام في آخر القائمة.
          OrderingTerm.asc(_db.textTemplates.caseTypeId.isNull()),
          OrderingTerm.asc(_db.lookupItems.sortOrder),
        ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          TemplateListItem(
            template: row.readTable(_db.textTemplates),
            caseTypeLabel: row.readTableOrNull(_db.lookupItems)?.label,
          ),
      ],
    );
  }

  Future<TextTemplate?> byId(String id) => (_db.select(
    _db.textTemplates,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateBody(String id, String body) {
    return (_db.update(_db.textTemplates)..where((t) => t.id.equals(id))).write(
      TextTemplatesCompanion(
        body: Value(body.trim()),
        updatedAt: Value(_clock().toUtc()),
      ),
    );
  }

  /// نص القالب الافتراضي الأصلي (لزر "استعادة الافتراضي")، أو null لقالب أضافه المستخدم.
  String? defaultBodyFor(TextTemplate template) {
    if (template.id == DefaultTemplates.genericId) {
      return DefaultTemplates.byCaseType[null]!.$2;
    }
    for (final code in DefaultTemplates.byCaseType.keys.whereType<String>()) {
      if (template.caseTypeId == lookupId(LookupKeys.caseType, code)) {
        return DefaultTemplates.byCaseType[code]!.$2;
      }
    }
    return null;
  }

  /// ينشئ قالبًا لنوع حالة ليس له قالب خاص (يبدأ من نص القالب العام).
  Future<String> createForCaseType(String caseTypeId, String name) async {
    final generic = await byId(DefaultTemplates.genericId);
    final id = 'template:$caseTypeId';
    await _db
        .into(_db.textTemplates)
        .insert(
          TextTemplatesCompanion.insert(
            id: id,
            caseTypeId: Value(caseTypeId),
            name: name,
            body: generic?.body ?? '',
            updatedAt: _clock().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }
}
