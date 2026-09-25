import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// الوصول إلى الحالات. يُستكمل (إنشاء/تعديل/حذف) في المرحلة 3.
class CasesRepository {
  CasesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// عدد الحالات غير المحذوفة التي وقعت اليوم (بالتوقيت المحلي).
  Stream<int> watchTodayCount() {
    final now = _clock();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = DateTime(now.year, now.month, now.day + 1).toUtc();
    final count = _db.cases.id.count();
    final query = _db.selectOnly(_db.cases)
      ..addColumns([count])
      ..where(
        _db.cases.deletedAt.isNull() &
            _db.cases.occurredAt.isBiggerOrEqualValue(startOfDay) &
            _db.cases.occurredAt.isSmallerThanValue(endOfDay),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }
}
