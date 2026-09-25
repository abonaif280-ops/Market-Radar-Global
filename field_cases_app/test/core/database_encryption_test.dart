import 'dart:io';

import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/security/database_encryption.dart';
import 'package:field_cases/core/security/secret_store.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory temp;
  setUp(() async => temp = await Directory.systemTemp.createTemp('db_enc'));
  tearDown(() => temp.delete(recursive: true));

  AppDatabase openEncrypted(File file, String key) => AppDatabase(
    NativeDatabase(
      file,
      setup: (db) => db.execute(DatabaseEncryption.keyPragma(key)),
    ),
  );

  bool isPlainSqlite(File file) =>
      String.fromCharCodes(file.readAsBytesSync().sublist(0, 15)) ==
      'SQLite format 3';

  test('key is generated once, 256-bit hex, kept in secure storage', () async {
    final secrets = MemorySecretStore();
    final enc = DatabaseEncryption(secrets);
    final key = await enc.obtainKey();
    expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await enc.obtainKey(), key);
    expect(secrets.values[DatabaseEncryption.keyName], key);
    expect(() => DatabaseEncryption.keyPragma("x'; DROP"), throwsArgumentError);
  });

  test('database file is unreadable without the key', () async {
    final key = await DatabaseEncryption(MemorySecretStore()).obtainKey();
    final file = File(p.join(temp.path, 'field_cases.sqlite'));
    final db = openEncrypted(file, key);
    await SettingsRepository(db).set('org_name', 'شرطة ينبع');
    await db.close();

    expect(isPlainSqlite(file), isFalse);
    final raw = sqlite3.open(file.path);
    expect(() => raw.select('SELECT * FROM app_settings'), throwsA(anything));
    raw.close();

    final again = openEncrypted(file, key);
    expect(await SettingsRepository(again).get('org_name'), 'شرطة ينبع');
    await again.close();
  });

  test('an older unencrypted database is encrypted in place', () async {
    final file = File(p.join(temp.path, 'field_cases.sqlite'));
    final plain = AppDatabase(NativeDatabase(file));
    await SettingsRepository(plain).set('org_name', 'بيانات قديمة');
    await plain.close();
    expect(isPlainSqlite(file), isTrue);

    final key = await DatabaseEncryption(MemorySecretStore()).obtainKey();
    expect(await DatabaseEncryption.encryptIfPlain(file, key), isTrue);
    expect(isPlainSqlite(file), isFalse);
    // مرة ثانية لا تفعل شيئًا.
    expect(await DatabaseEncryption.encryptIfPlain(file, key), isFalse);

    final db = openEncrypted(file, key);
    expect(await SettingsRepository(db).get('org_name'), 'بيانات قديمة');
    await db.close();
  });
}
