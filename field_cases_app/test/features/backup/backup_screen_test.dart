import 'dart:io';

import 'package:field_cases/app/app_restart.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:field_cases/core/platform/share_service.dart';
import 'package:field_cases/core/security/secret_store.dart';
import 'package:field_cases/features/backup/data/backup_service.dart';
import 'package:field_cases/features/backup/presentation/backup_screen.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _manifest = BackupManifest(
  formatVersion: 1,
  schemaVersion: 3,
  appVersion: '1.0.0',
  createdAt: DateTime.utc(2026, 9, 20, 8),
  deviceId: 'DEV-1',
  userCode: 'U-117',
  orgName: 'مركز العوالي',
  caseCount: 12,
  attachmentCount: 30,
  includesSupervisorKeys: false,
);

class FakeBackup implements BackupService {
  final passwords = <String>[];
  var stageAttempts = 0;
  var prepared = false;
  var discarded = false;

  @override
  Future<BackupResult> create({
    required String password,
    bool includeSupervisorKeys = false,
  }) async {
    passwords.add(password);
    return BackupResult(
      file: File('/tmp/FieldCases-Backup-20260925-1930.fcbackup'),
      manifest: _manifest,
    );
  }

  @override
  Future<StagedRestore> stage(File file, String password) async {
    stageAttempts++;
    if (password != 'correct-horse') {
      throw const BackupException(
        'كلمة المرور غير صحيحة، أو الملف معدل أو غير مكتمل',
        wrongPassword: true,
      );
    }
    return StagedRestore(
      directory: Directory.systemTemp,
      manifest: _manifest,
      caseCount: 12,
      attachmentCount: 30,
      missingFiles: 0,
      secrets: const {},
    );
  }

  @override
  Future<void> prepare(StagedRestore staged) async => prepared = true;

  @override
  Future<void> discard(StagedRestore staged) async => discarded = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCases implements CasesRepository {
  @override
  Future<int> countCases(CaseQuery query) async => 5;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRestart extends AppRestartController {
  var restarted = false;

  @override
  Future<void> restart({
    required Future<void> Function() whileClosed,
    AfterReopen? afterReopen,
  }) async => restarted = true;
}

class FakeShare implements ShareService {
  String? sharedPath;

  @override
  Future<void> shareFile(String path, {String? text}) async =>
      sharedPath = path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeBackup backup;
  late FakeRestart restart;
  late FakeShare share;

  Future<void> pump(WidgetTester tester) async {
    backup = FakeBackup();
    restart = FakeRestart();
    share = FakeShare();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(backup),
          casesRepositoryProvider.overrideWithValue(FakeCases()),
          appRestartProvider.overrideWithValue(restart),
          shareServiceProvider.overrideWithValue(share),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          databaseFileProvider.overrideWithValue(File('/tmp/x.sqlite')),
          attachmentStorageProvider.overrideWithValue(
            AttachmentStorage(Directory.systemTemp),
          ),
          userRoleProvider.overrideWith(
            (ref) => Stream.value(UserRole.employee),
          ),
          lastBackupAtProvider.overrideWith((ref) => Stream.value(null)),
          backupFilePickerProvider.overrideWithValue(
            () async => '/tmp/some.fcbackup',
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BackupScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('create asks for a confirmed password and acknowledgement', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('لم تُنشأ نسخة احتياطية بعد'), findsOneWidget);

    await tester.tap(find.text('إنشاء نسخة احتياطية'));
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'إنشاء');
    // الزر معطل حتى الإقرار بعدم إمكانية استرجاع كلمة المرور.
    expect(tester.widget<FilledButton>(create).onPressed, isNull);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.textContaining('أفهم أنه'));
    await tester.pumpAndSettle();
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.textContaining('أحرف على الأقل'), findsWidgets);
    expect(backup.passwords, isEmpty);

    await tester.enterText(fields.at(0), 'correct-horse');
    await tester.enterText(fields.at(1), 'correct-hors');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);

    await tester.enterText(fields.at(1), 'correct-horse');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(backup.passwords, ['correct-horse']);
    expect(find.text('النسخة جاهزة ومشفرة'), findsOneWidget);

    await tester.tap(find.text('حفظ الملف أو مشاركته'));
    expect(share.sharedPath, endsWith('.fcbackup'));
  });

  testWidgets('restore retries wrong password, warns, then restarts', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nope-nope');
    await tester.tap(find.text('فتح النسخة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('كلمة المرور غير صحيحة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'correct-horse');
    await tester.tap(find.text('فتح النسخة'));
    await tester.pumpAndSettle();
    expect(backup.stageAttempts, 2);
    expect(find.text('استبدال البيانات الحالية؟'), findsOneWidget);
    expect(find.textContaining('5 حالة'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.text('استبدال البيانات'));
    await tester.pumpAndSettle();
    expect(backup.prepared, isTrue);
    expect(restart.restarted, isTrue);
  });

  testWidgets('cancelling the warning discards the staged backup', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'correct-horse');
    await tester.tap(find.text('فتح النسخة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(backup.discarded, isTrue);
    expect(restart.restarted, isFalse);
  });
}
