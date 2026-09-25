import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/arabic_text.dart';

/// فهرس البحث النصي (SQLite FTS5 بمقسّم trigram):
///
/// - يطابق أي جزء من الكلمة (3 أحرف فأكثر)، فيجد "المتفجرات" داخل "والمتفجرات".
/// - النص يُوحَّد بـ [ArabicText.normalize] قبل الفهرسة وقبل البحث.
/// - يشمل رقم الحالة، والنوع، والمحافظة، والمركز، والمصدر، والجهات، والموقع،
///   والوصف، والمعلومات، والإجراء، والملاحظات، ونص الحالة.
///
/// الفهرس مشتق بالكامل من جداول الحالات، ويمكن إعادة بنائه في أي وقت.
class CaseSearchIndex {
  CaseSearchIndex(this._db);

  static const String table = 'cases_fts';

  static const String createStatement =
      "CREATE VIRTUAL TABLE IF NOT EXISTS $table "
      "USING fts5(case_id UNINDEXED, content, tokenize='trigram')";

  /// أقل طول لجزء يُبحث عنه عبر الفهرس؛ الأقصر يُبحث عنه بـ LIKE.
  static const int minTrigram = 3;

  final AppDatabase _db;

  /// يُستدعى داخل Transaction الحفظ حتى يبقى الفهرس متسقًا مع البيانات.
  Future<void> reindexCase(String caseId) async {
    await _db.customStatement('DELETE FROM $table WHERE case_id = ?', [caseId]);
    final content = await _contentFor(caseId);
    if (content == null) return;
    await _db.customStatement(
      'INSERT INTO $table (case_id, content) VALUES (?, ?)',
      [caseId, content],
    );
  }

  Future<void> removeCase(String caseId) =>
      _db.customStatement('DELETE FROM $table WHERE case_id = ?', [caseId]);

  /// إعادة بناء الفهرس كاملًا (بعد Migration أو تغيير أسماء القوائم).
  Future<void> rebuildAll() {
    return _db.transaction(() async {
      await _db.customStatement('DELETE FROM $table');
      final ids = await (_db.selectOnly(
        _db.cases,
      )..addColumns([_db.cases.id])).map((r) => r.read(_db.cases.id)!).get();
      for (final id in ids) {
        final content = await _contentFor(id);
        if (content == null) continue;
        await _db.customStatement(
          'INSERT INTO $table (case_id, content) VALUES (?, ?)',
          [id, content],
        );
      }
    });
  }

  /// معرفات الحالات المطابقة لكل كلمات الاستعلام (AND)، أو null إذا كان الاستعلام فارغًا.
  Future<Set<String>?> search(String query) async {
    final terms = ArabicText.normalize(query)
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return null;

    final longTerms = terms.where((t) => t.length >= minTrigram).toList();
    final shortTerms = terms.where((t) => t.length < minTrigram).toList();

    final where = <String>[];
    final variables = <Variable<Object>>[];
    if (longTerms.isNotEmpty) {
      where.add('$table MATCH ?');
      variables.add(Variable.withString(longTerms.map(_quote).join(' AND ')));
    }
    for (final term in shortTerms) {
      where.add(r"content LIKE ? ESCAPE '\'");
      variables.add(Variable.withString('%${_escapeLike(term)}%'));
    }
    final rows = await _db
        .customSelect(
          'SELECT case_id FROM $table WHERE ${where.join(' AND ')}',
          variables: variables,
        )
        .get();
    return {for (final r in rows) r.read<String>('case_id')};
  }

  Future<String?> _contentFor(String caseId) async {
    final row = await (_db.select(
      _db.cases,
    )..where((c) => c.id.equals(caseId))).getSingleOrNull();
    if (row == null) return null;

    final lookupIds = {
      row.caseTypeId,
      ?row.governorateId,
      ?row.centerId,
      ?row.reportSourceId,
    };
    final labels = await (_db.select(
      _db.lookupItems,
    )..where((l) => l.id.isIn(lookupIds))).map((l) => l.label).get();
    final parties =
        await (_db.select(_db.caseParties).join([
              innerJoin(
                _db.lookupItems,
                _db.lookupItems.id.equalsExp(_db.caseParties.partyId),
              ),
            ])..where(_db.caseParties.caseId.equals(caseId)))
            .map((r) => r.readTable(_db.lookupItems).label)
            .get();

    final parts = <String?>[
      row.displayCode,
      '${row.serialNo}',
      ...labels,
      ...parties,
      row.locationText,
      row.locationDescription,
      row.caseInfo,
      row.actionTaken,
      row.damageDescription,
      row.notes,
      row.finalText,
      row.enteredBy,
    ];
    return ArabicText.normalize(
      parts.whereType<String>().where((p) => p.trim().isNotEmpty).join(' | '),
    );
  }

  /// كل كلمة تُبحث كعبارة حرفية (بين علامتي تنصيص) لتجنب رموز FTS الخاصة.
  static String _quote(String term) => '"${term.replaceAll('"', '""')}"';

  static String _escapeLike(String term) => term
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
