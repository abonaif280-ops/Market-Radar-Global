import 'package:field_cases/app/app.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  Future<_FakeCasesRepository> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final fake = _FakeCasesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesRepositoryProvider.overrideWithValue(fake),
          userRoleProvider.overrideWith(
            (ref) => Stream.value(UserRole.employee),
          ),
          orgNameProvider.overrideWith((ref) => Stream.value('شرطة بدر')),
          todayCasesCountProvider.overrideWith((ref) => Stream.value(0)),
          recentCasesProvider.overrideWith((ref) => Stream.value(const [])),
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
    expect(find.text('الخطوة 1 من 4'), findsOneWidget);

    // الخطوة 1: النوع ينقل تلقائيًا للخطوة التالية.
    await tester.tap(find.text('جسم صلب'));
    await tester.pumpAndSettle();
    expect(find.text('الخطوة 2 من 4'), findsOneWidget);

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

    // الخطوة 4: المراجعة والحفظ.
    expect(find.text('الخطوة 4 من 4'), findsOneWidget);
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
  });

  testWidgets('incomplete case shows errors but can be saved as draft', (
    tester,
  ) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حريق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('اختر المحافظة'), findsOneWidget);
    expect(find.text('اختر مصدر البلاغ'), findsOneWidget);

    await tester.tap(find.text('حفظ الحالة'));
    await tester.pumpAndSettle();
    expect(fake.created, isEmpty);
    expect(find.text('الخطوة 2 من 4'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
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
}
