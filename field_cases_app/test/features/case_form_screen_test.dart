import 'dart:io';

import 'package:field_cases/app/app.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:field_cases/core/location/coordinates.dart';
import 'package:field_cases/core/location/location_service.dart';
import 'package:field_cases/core/platform/map_launcher.dart';
import 'package:field_cases/core/platform/share_service.dart';
import 'package:field_cases/features/templates/data/case_text_composer.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/cases/domain/case_type_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// مستودع وهمي يلتقط ما يُحفظ دون قاعدة بيانات (الواجهة تُختبر بمعزل).
class _FakeCasesRepository implements CasesRepository {
  final List<(CaseFormData, CaseStatus)> created = [];

  @override
  Future<String> createCase(
    CaseFormData data, {
    required CaseStatus status,
  }) async {
    created.add((data, status));
    return 'new-id';
  }

  @override
  Stream<int> watchTodayCount() => Stream.value(0);

  @override
  Future<CasePage> searchCases(
    CaseQuery query, {
    CaseCursor? after,
    int limit = 30,
  }) async => const CasePage([], null);

  @override
  Future<int> countCases(CaseQuery query) async => 0;

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationService implements LocationService {
  LocationResult result = const LocationSuccess(
    Coordinates(24.468245, 39.612354),
    accuracyMeters: 8,
  );

  @override
  Future<LocationResult> currentLocation() async => result;

  @override
  Future<void> openSystemSettings() async {}
}

class _FakeComposer implements CaseTextComposer {
  int calls = 0;

  @override
  Future<String> compose(CaseFormData data) async {
    calls++;
    return 'نص مولد للحالة';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShareService implements ShareService {
  final shared = <String>[];
  final copied = <String>[];

  @override
  Future<void> copyText(String text) async => copied.add(text);

  @override
  Future<void> shareText(String text, {String? subject}) async =>
      shared.add(text);

  @override
  Future<void> shareTextWithFiles(
    String text,
    List<String> filePaths, {
    String? subject,
  }) async => shared.add(text);
}

class _FakeMapLauncher implements MapLauncher {
  final opened = <Coordinates>[];

  @override
  Future<bool> open(Coordinates coordinates, {String? label}) async {
    opened.add(coordinates);
    return true;
  }
}

LookupItem _item(String listKey, String code, String label, int order) =>
    LookupItem(
      id: lookupId(listKey, code),
      listKey: listKey,
      code: code,
      label: label,
      sortOrder: order,
      isActive: true,
      isSystem: true,
    );

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  final lookups = {
    LookupKeys.caseType: [
      _item(LookupKeys.caseType, 'SOLID_OBJECT', 'جسم صلب', 0),
      _item(LookupKeys.caseType, 'FIRE', 'حريق', 1),
    ],
    LookupKeys.governorate: [_item(LookupKeys.governorate, 'BADR', 'بدر', 0)],
    LookupKeys.reportSource: [
      _item(LookupKeys.reportSource, '911', 'العمليات الموحدة (911)', 0),
    ],
    LookupKeys.party: [
      _item(LookupKeys.party, 'CIVIL_DEF', 'الدفاع المدني', 0),
    ],
    LookupKeys.center: <LookupItem>[],
  };

  late _FakeComposer composer;
  late _FakeShareService share;

  Future<_FakeCasesRepository> pumpApp(WidgetTester tester) async {
    composer = _FakeComposer();
    share = _FakeShareService();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final fake = _FakeCasesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesRepositoryProvider.overrideWithValue(fake),
          attachmentStorageProvider.overrideWithValue(
            AttachmentStorage(Directory.systemTemp),
          ),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
          mapLauncherProvider.overrideWithValue(_FakeMapLauncher()),
          caseTextComposerProvider.overrideWithValue(composer),
          shareServiceProvider.overrideWithValue(share),
          userRoleProvider.overrideWith(
            (ref) => Stream.value(UserRole.employee),
          ),
          orgNameProvider.overrideWith((ref) => Stream.value('شرطة بدر')),
          todayCasesCountProvider.overrideWith((ref) => Stream.value(0)),
          caseDetailsProvider.overrideWith((ref, id) => Stream.value(null)),
          activeLookupProvider.overrideWith(
            (ref, args) => Stream.value(lookups[args.listKey]!),
          ),
          caseTypeFieldsProvider.overrideWith(
            (ref, id) async => const [
              CaseTypeFieldDef(
                fieldKey: 'has_fire',
                label: 'وجود حريق',
                inputType: FieldInputType.boolean,
              ),
            ],
          ),
          lookupItemProvider.overrideWith(
            (ref, id) async => lookups.values
                .expand((l) => l)
                .where((i) => i.id == id)
                .firstOrNull,
          ),
        ],
        child: const FieldCasesApp(),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  Future<void> selectDropdown(
    WidgetTester tester,
    String label,
    String option,
  ) async {
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, label),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('employee creates a completed case through the steps', (
    tester,
  ) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);

    // الخطوة 1: النوع ينقل تلقائيًا للخطوة التالية.
    await tester.tap(find.text('جسم صلب'));
    await tester.pumpAndSettle();
    expect(find.text('الخطوة 2 من 5'), findsOneWidget);

    // الخطوة 2: الأساسيات.
    await selectDropdown(tester, 'مصدر البلاغ *', 'العمليات الموحدة (911)');
    await selectDropdown(tester, 'المحافظة *', 'بدر');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'الموقع'),
      'جنوب مركز الرايس',
    );
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    // الخطوة 3: الحقل الخاص بالنوع + الجهات.
    expect(find.text('وجود حريق'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'وجود حريق'));
    await tester.tap(find.text('الدفاع المدني'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    // الخطوة 4: الموقع (من خدمة موقع وهمية).
    expect(find.text('الخطوة 4 من 5'), findsOneWidget);
    await tester.tap(find.text('التقاط الموقع الحالي'));
    await tester.pumpAndSettle();
    expect(find.text('24.468245, 39.612354'), findsOneWidget);
    expect(find.text('الدقة التقريبية 8 م'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    // الخطوة 5: المعاينة بالنص المولد ثم الحفظ.
    expect(find.text('الخطوة 5 من 5'), findsOneWidget);
    expect(find.text('نص مولد للحالة'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    await tester.tap(find.text('حفظ الحالة'));
    await tester.pumpAndSettle();

    final (data, status) = fake.created.single;
    expect(status, CaseStatus.completed);
    expect(data.caseTypeId, lookupId(LookupKeys.caseType, 'SOLID_OBJECT'));
    expect(data.reportSourceId, lookupId(LookupKeys.reportSource, '911'));
    expect(data.governorateId, lookupId(LookupKeys.governorate, 'BADR'));
    expect(data.locationText, 'جنوب مركز الرايس');
    expect(data.extraFields['has_fire'], isTrue);
    expect(data.partyIds, {lookupId(LookupKeys.party, 'CIVIL_DEF')});
    expect(data.latitude, 24.468245);
    expect(data.finalText, 'نص مولد للحالة');
    expect(data.isTextEdited, isFalse);
    expect(data.longitude, 39.612354);
  });

  testWidgets('incomplete case shows errors but can be saved as draft', (
    tester,
  ) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حريق'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }

    expect(find.text('اختر المحافظة'), findsOneWidget);
    expect(find.text('اختر مصدر البلاغ'), findsOneWidget);

    await tester.tap(find.text('حفظ الحالة'));
    await tester.pumpAndSettle();
    expect(fake.created, isEmpty);
    expect(find.text('الخطوة 2 من 5'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('حفظ كمسودة'));
    await tester.pumpAndSettle();
    expect(fake.created.single.$2, CaseStatus.draft);
  });

  testWidgets('closing with unsaved data asks for confirmation', (
    tester,
  ) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جسم صلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();

    expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
    await tester.tap(find.text('خروج دون حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('الحالات الميدانية'), findsOneWidget);
    expect(fake.created, isEmpty);
  });

  testWidgets('coordinates can be entered manually with Arabic digits', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جسم صلب'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('إدخال يدوي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '٢٤٫٥، ٣٩٫٦');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('24.500000, 39.600000'), findsOneWidget);
    expect(find.text('تعديل يدوي'), findsOneWidget);

    await tester.tap(find.text('إزالة'));
    await tester.pumpAndSettle();
    expect(find.text('لم تُضف إحداثيات'), findsOneWidget);
  });

  testWidgets('invalid manual coordinates show an error', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جسم صلب'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('إدخال يدوي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '124, 39');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('الصيغة'), findsOneWidget);
  });

  testWidgets('preview text can be edited, copied, shared and regenerated', (
    tester,
  ) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جسم صلب'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
    expect(find.text('معاينة الحالة'), findsOneWidget);

    final editor = find.widgetWithText(TextField, 'نص مولد للحالة');
    await tester.enterText(editor, 'نص معدل يدويًا');
    await tester.pumpAndSettle();
    expect(find.text('معدّل يدويًا'), findsOneWidget);

    await tester.tap(find.text('نسخ النص'));
    await tester.pumpAndSettle();
    expect(share.copied.single, 'نص معدل يدويًا');

    await tester.tap(find.text('مشاركة'));
    await tester.pumpAndSettle();
    expect(share.shared.single, 'نص معدل يدويًا');

    // إعادة الصياغة تطلب تأكيدًا لأن النص معدل.
    await tester.ensureVisible(find.text('إعادة الصياغة من البيانات'));
    await tester.tap(find.text('إعادة الصياغة من البيانات'));
    await tester.pumpAndSettle();
    expect(find.text('إعادة الصياغة؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // الحفظ كمسودة يحفظ النص المعدل كما هو دون إعادة صياغته.
    final callsBeforeSave = composer.calls;
    await tester.tap(find.text('حفظ كمسودة'));
    await tester.pumpAndSettle();
    final (data, _) = fake.created.single;
    expect(data.finalText, 'نص معدل يدويًا');
    expect(data.isTextEdited, isTrue);
    expect(composer.calls, callsBeforeSave);
  });
}
