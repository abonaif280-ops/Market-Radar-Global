import 'dart:io';

import 'package:field_cases/app/providers.dart';
import 'package:field_cases/app/theme.dart';
import 'package:field_cases/core/crypto/key_manager.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/cases/domain/case_views.dart';
import 'package:field_cases/features/import/data/import_service.dart';
import 'package:field_cases/features/import/presentation/import_screen.dart';
import 'package:field_cases/features/packages/data/case_package_reader.dart';
import 'package:field_cases/features/packages/domain/package_models.dart';
import 'package:field_cases/features/supervisor/data/inbox_repository.dart';
import 'package:field_cases/features/supervisor/data/role_service.dart';
import 'package:field_cases/features/supervisor/presentation/supervisor_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Roles implements RoleService {
  bool hasPin = false;
  String? setupWith;
  final attempts = <String>[];

  @override
  Future<bool> hasSupervisorPin() async => hasPin;

  @override
  Future<void> setupSupervisor(String pin) async => setupWith = pin;

  @override
  Future<RoleChangeResult> switchToSupervisor(String pin) async {
    attempts.add(pin);
    return pin == '246810'
        ? const RoleChanged()
        : WrongPin(5 - attempts.length);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

PackagedCase _case(String id, String type) => PackagedCase(
  caseUuid: id,
  displayCode: 'EVT-20260925-${id.toUpperCase()}',
  serialNo: 1,
  revision: 1,
  contentHash: 'h$id',
  status: 'completed',
  caseType: PackagedLookup(
    code: type,
    label: type == 'FIRE' ? 'حريق' : 'جسم صلب',
  ),
  occurredAt: DateTime(2026, 9, 25, 14),
  originDeviceId: 'DEV-1',
  createdAt: DateTime(2026, 9, 25),
  updatedAt: DateTime(2026, 9, 25),
  governorate: const PackagedLookup(code: 'YNB', label: 'ينبع'),
);

class _Importer implements ImportService {
  int commits = 0;

  @override
  Future<ImportReport> prepare(String pickedPath) async {
    final manifest = PackageManifest(
      packageFormatVersion: 1,
      packageId: 'pkg-1',
      createdAt: DateTime(2026, 9, 25, 16),
      createdAtLocal: null,
      appVersion: '1.0.0+1',
      source: const PackageSource(
        deviceId: 'DEV-1',
        orgName: 'شرطة ينبع',
        enteredBy: 'U-117',
      ),
      scope: 'unexported',
      caseCount: 3,
      imageCount: 5,
      attachmentCount: 5,
      files: const [],
      contentSha256: 'x',
    );
    return ImportReport(
      packageFile: File(pickedPath),
      inspection: PackageInspection(
        manifest: manifest,
        cases: const [],
        errors: const [],
      ),
      items: [
        ImportItem(
          packagedCase: _case('a1', 'SOLID_OBJECT'),
          classification: ImportClassification.newCase,
          decision: ImportDecision.import,
        ),
        ImportItem(
          packagedCase: _case('b2', 'FIRE'),
          classification: ImportClassification.newCase,
          decision: ImportDecision.import,
        ),
        ImportItem(
          packagedCase: _case('c3', 'FIRE'),
          classification: ImportClassification.newer,
          decision: ImportDecision.pending,
        ),
      ],
    );
  }

  @override
  Future<ImportOutcome> commit(ImportReport report) async {
    commits++;
    return const ImportOutcome(
      batchId: 'pkg-1',
      importedCases: 2,
      importedAttachments: 5,
      pendingDecisions: 1,
    );
  }

  @override
  Future<void> discard(ImportReport report) async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Cases implements CasesRepository {
  @override
  Future<CasePage> searchCases(
    CaseQuery q, {
    CaseCursor? after,
    int limit = 30,
  }) async => CasePage([
    CaseListItem(
      id: 'a1',
      displayCode: 'EVT-A1',
      serialNo: 1,
      occurredAt: DateTime.now(),
      caseTypeLabel: 'جسم صلب',
      placeLabel: 'ينبع',
      displayStatus: DisplayStatus.imported,
    ),
  ], null);
  @override
  Future<int> countCases(CaseQuery q) async => 1;
  @override
  Stream<void> watchChanges() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  Future<void> pump(
    WidgetTester tester,
    Widget home,
    List<Override> overrides,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    await tester.enterText(find.byType(TextField).last, pin);
    await tester.pumpAndSettle();
  }

  testWidgets('first activation asks for a new PIN twice', (tester) async {
    final roles = _Roles();
    await pump(tester, const SupervisorModeScreen(), [
      roleServiceProvider.overrideWithValue(roles),
      userRoleProvider.overrideWith((ref) => Stream.value(UserRole.employee)),
      supervisorPublicKeyProvider.overrideWith((ref) async => null),
    ]);

    expect(find.text('الوضع الحالي: موظف'), findsOneWidget);
    await tester.tap(find.text('التحويل إلى وضع المشرف'));
    await tester.pumpAndSettle();

    expect(find.text('رمز المشرف الجديد'), findsOneWidget);
    await enterPin(tester, '246810');
    expect(find.text('تأكيد الرمز'), findsOneWidget);
    await enterPin(tester, '111111');
    // غير متطابق: يعيد الطلب مع رسالة.
    expect(find.text('الرمزان غير متطابقين، حاول مرة أخرى'), findsOneWidget);
    await enterPin(tester, '246810');
    await enterPin(tester, '246810');

    expect(roles.setupWith, '246810');
    expect(find.text('تم تفعيل وضع المشرف'), findsOneWidget);
  });

  testWidgets('wrong PIN shows remaining attempts', (tester) async {
    final roles = _Roles()..hasPin = true;
    await pump(tester, const SupervisorModeScreen(), [
      roleServiceProvider.overrideWithValue(roles),
      userRoleProvider.overrideWith((ref) => Stream.value(UserRole.employee)),
      supervisorPublicKeyProvider.overrideWith((ref) async => null),
    ]);

    await tester.tap(find.text('التحويل إلى وضع المشرف'));
    await tester.pumpAndSettle();
    await enterPin(tester, '000000');
    expect(find.text('رمز غير صحيح. المحاولات المتبقية: 4'), findsOneWidget);
    await enterPin(tester, '246810');
    expect(find.text('تم التحويل إلى وضع المشرف'), findsOneWidget);
  });

  testWidgets('supervisor sees the key fingerprint', (tester) async {
    await pump(tester, const SupervisorModeScreen(), [
      roleServiceProvider.overrideWithValue(_Roles()),
      userRoleProvider.overrideWith((ref) => Stream.value(UserRole.supervisor)),
      supervisorPublicKeyProvider.overrideWith(
        (ref) async => SupervisorPublicKey(List.filled(32, 7)),
      ),
    ]);
    expect(find.text('الوضع الحالي: مشرف'), findsOneWidget);
    expect(
      find.text(SupervisorPublicKey.fingerprintOf(List.filled(32, 7))),
      findsOneWidget,
    );
    expect(find.text('العودة لوضع الموظف'), findsOneWidget);
  });

  testWidgets('import: pick, inspect report, approve, then review batch', (
    tester,
  ) async {
    final importer = _Importer();
    await pump(tester, const ImportScreen(), [
      importServiceProvider.overrideWithValue(importer),
      packageFilePickerProvider.overrideWithValue(
        () async => '/tmp/ينبع_20260925.casepkg',
      ),
      casesRepositoryProvider.overrideWithValue(_Cases()),
      inboxBatchesProvider.overrideWith(
        (ref) => Stream.value([
          InboxBatch(
            id: 'pkg-1',
            orgName: 'شرطة ينبع',
            enteredBy: 'U-117',
            packageCreatedAt: DateTime(2026, 9, 25),
            importedAt: DateTime(2026, 9, 25),
            caseCount: 2,
            imageCount: 5,
            pendingCount: 2,
            approvedCount: 0,
            rejectedCount: 0,
          ),
        ]),
      ),
    ]);

    await tester.tap(find.text('اختيار ملف'));
    await tester.pumpAndSettle();

    expect(find.text('الدفعة: شرطة ينبع'), findsOneWidget);
    expect(find.text('جديدة'), findsOneWidget);
    expect(find.text('لها نسخة أحدث'), findsOneWidget);
    expect(find.textContaining('ستظهر في الدفعة'), findsOneWidget);

    await tester.tap(find.text('اعتماد الاستيراد'));
    await tester.pumpAndSettle();
    expect(importer.commits, 1);
    expect(find.text('تم الاستيراد'), findsOneWidget);
    expect(find.textContaining('1 حالة لها نسخة أحدث'), findsOneWidget);

    await tester.tap(find.text('مراجعة الدفعة'));
    await tester.pumpAndSettle();
    expect(find.text('دفعة شرطة ينبع'), findsOneWidget);
    expect(find.text('اعتماد الكل (2)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('اعتماد (1)'), findsOneWidget);
    expect(find.text('رفض (1)'), findsOneWidget);
  });
}
