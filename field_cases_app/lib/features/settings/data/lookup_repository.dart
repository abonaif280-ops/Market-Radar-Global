import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';

/// الوصول إلى القوائم القابلة للتعديل (أنواع الحالات، المحافظات، ...).
class LookupRepository {
  LookupRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  SimpleSelectStatement<$LookupItemsTable, LookupItem> _activeQuery(
    String listKey, {
    String? parentId,
  }) {
    final query = _db.select(_db.lookupItems)
      ..where((l) => l.listKey.equals(listKey) & l.isActive.equals(true))
      ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]);
    if (parentId != null) {
      query.where((l) => l.parentId.equals(parentId));
    }
    return query;
  }

  Future<List<LookupItem>> activeItems(String listKey, {String? parentId}) {
    return _activeQuery(listKey, parentId: parentId).get();
  }

  Stream<List<LookupItem>> watchActiveItems(
    String listKey, {
    String? parentId,
  }) {
    return _activeQuery(listKey, parentId: parentId).watch();
  }

  Future<LookupItem?> byId(String id) {
    return (_db.select(
      _db.lookupItems,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<String> add({
    required String listKey,
    required String label,
    String? code,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    final maxOrder = _db.lookupItems.sortOrder.max();
    final currentMax =
        await (_db.selectOnly(_db.lookupItems)
              ..addColumns([maxOrder])
              ..where(_db.lookupItems.listKey.equals(listKey)))
            .map((row) => row.read(maxOrder))
            .getSingle();
    await _db
        .into(_db.lookupItems)
        .insert(
          LookupItemsCompanion.insert(
            id: id,
            listKey: listKey,
            code: code ?? id,
            label: label.trim(),
            parentId: Value(parentId),
            sortOrder: Value((currentMax ?? -1) + 1),
          ),
        );
    return id;
  }

  /// التعطيل بدل الحذف حتى لا تنكسر الحالات القديمة المرتبطة بالعنصر.
  Future<void> setActive(String id, {required bool active}) {
    return (_db.update(_db.lookupItems)..where((l) => l.id.equals(id))).write(
      LookupItemsCompanion(isActive: Value(active)),
    );
  }

  Future<void> rename(String id, String label) {
    return (_db.update(_db.lookupItems)..where((l) => l.id.equals(id))).write(
      LookupItemsCompanion(label: Value(label.trim())),
    );
  }
}
