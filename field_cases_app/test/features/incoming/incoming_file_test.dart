import 'dart:async';
import 'dart:io';

import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/crypto/backup_cipher.dart';
import 'package:field_cases/core/platform/incoming_files.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/incoming/incoming_file_listener.dart';
import 'package:field_cases/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class FakeIncoming implements IncomingFiles {
  FakeIncoming(this.initial);

  final String? initial;
  final controller = StreamController<String>.broadcast();

  @override
  Future<String?> initialFile() async => initial;

  @override
  Stream<String> get files => controller.stream;
}

class FakeSettings implements SettingsRepository {
  FakeSettings(this.role);

  final UserRole role;

  @override
  Stream<UserRole> watchRole() => Stream.value(role);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('incoming'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File write(String name, List<int> bytes) =>
      File(p.join(tmp.path, name))..writeAsBytesSync(bytes);

  test('files are recognised by content, not by name', () async {
    final zip = write('x.bin', [0x50, 0x4B, 0x03, 0x04, 1, 2]);
    final encrypted = write('y', [...'CASEPKG'.codeUnits, 0, 0, 1]);
    final backup = write('z.casepkg', [...BackupCipher.magic, 0, 1]);
    final other = write('photo.casepkg', [0xFF, 0xD8, 0xFF]);

    expect(await classifyIncoming(zip), IncomingKind.package);
    expect(await classifyIncoming(encrypted), IncomingKind.package);
    expect(await classifyIncoming(backup), IncomingKind.backup);
    expect(await classifyIncoming(other), IncomingKind.unsupported);
    expect(
      await classifyIncoming(File(p.join(tmp.path, 'missing'))),
      IncomingKind.unsupported,
    );
  });

  Future<void> pump(
    WidgetTester tester,
    String path,
    UserRole role,
    IncomingKind kind,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incomingFilesProvider.overrideWithValue(FakeIncoming(path)),
          settingsRepositoryProvider.overrideWithValue(FakeSettings(role)),
          incomingClassifierProvider.overrideWithValue((_) async => kind),
        ],
        child: const MaterialApp(
          home: IncomingFileListener(child: Scaffold(body: Text('home'))),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an employee opening a package is told it is for supervisors', (
    tester,
  ) async {
    await pump(
      tester,
      '/tmp/none/a.casepkg',
      UserRole.employee,
      IncomingKind.package,
    );
    expect(find.text('استيراد الحزم للمشرف'), findsOneWidget);
    await tester.tap(find.text('حسنًا'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('unsupported files are refused with a clear message', (
    tester,
  ) async {
    await pump(
      tester,
      '/tmp/none/b.pdf',
      UserRole.supervisor,
      IncomingKind.unsupported,
    );
    expect(find.text('ملف غير مدعوم'), findsOneWidget);
  });
}
