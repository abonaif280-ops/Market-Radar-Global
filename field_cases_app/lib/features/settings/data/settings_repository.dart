import 'dart:math';

import '../../../core/db/app_database.dart';
import '../../cases/domain/case_enums.dart';

/// مفاتيح الإعدادات غير الحساسة في جدول app_settings.
abstract final class SettingKeys {
  static const deviceId = 'device_id';
  static const orgName = 'org_name';
  static const orgCode = 'org_code';
  static const userCode = 'user_code';
  static const role = 'role';
  static const lastSerialNo = 'last_serial_no';
}

class SettingsRepository {
  SettingsRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final Random _random;

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watch(String key) {
    return (_db.select(_db.appSettings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> set(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }

  /// معرف منطقي عشوائي للجهاز (ليس معرف عتاد) يُولَّد مرة واحدة.
  Future<String> deviceId() {
    return _db.transaction(() async {
      final existing = await get(SettingKeys.deviceId);
      if (existing != null) return existing;
      final hex = List.generate(
        6,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join().toUpperCase();
      final id = 'DEV-$hex';
      await set(SettingKeys.deviceId, id);
      return id;
    });
  }

  /// يحجز الرقم التسلسلي التالي للحالات داخل Transaction.
  Future<int> nextSerialNo() {
    return _db.transaction(() async {
      final last = int.tryParse(await get(SettingKeys.lastSerialNo) ?? '') ?? 0;
      final next = last + 1;
      await set(SettingKeys.lastSerialNo, '$next');
      return next;
    });
  }

  Stream<UserRole> watchRole() {
    return watch(SettingKeys.role).map(_parseRole);
  }

  Future<void> setRole(UserRole role) => set(SettingKeys.role, role.name);

  static UserRole _parseRole(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.employee,
    );
  }
}
