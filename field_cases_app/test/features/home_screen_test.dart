import 'package:field_cases/app/app.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/cases/domain/case_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// مستودع وهمي لقائمة الحالات: يسجل الاستعلامات ويعيد نتائج ثابتة.
class _ListFake implements CasesRepository {
  final queries = <CaseQuery>[];

  static final _items = [
    CaseListItem(
      id: '1',
      displayCode: 'EVT-20260925-A72F91',
      serialNo: 1,
      occurredAt: DateTime.now(),
      caseTypeLabel: 'جسم صلب',
      placeLabel: 'ينبع',
      displayStatus: DisplayStatus.exported,
      imageCount: 2,
    ),
  ];

  @override
  Future<CasePage> searchCases(
    CaseQuery query, {
    CaseCursor? after,
    int limit = 30,
  }) async {
    queries.add(query);
    return CasePage(query.text == 'لا شيء' ? const [] : _items, null);
  }

  @override
  Future<int> countCases(CaseQuery query) async =>
      query.text == 'لا شيء' ? 0 : 1;

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  Stream<int> watchTodayCount() => Stream.value(3);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  // الواجهة تُختبر بمعزل عن القاعدة؛ القاعدة لها اختباراتها المستقلة.
  Future<void> pumpApp(
    WidgetTester tester, {
    UserRole role = UserRole.employee,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRoleProvider.overrideWith((ref) => Stream.value(role)),
          orgNameProvider.overrideWith((ref) => Stream.value('شرطة ينبع')),
          userCodeProvider.overrideWith((ref) => Stream.value('U-117')),
          todayCasesCountProvider.overrideWith((ref) => Stream.value(3)),
          casesRepositoryProvider.overrideWithValue(_ListFake()),
        ],
        child: const FieldCasesApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('employee home is RTL and hides supervisor actions', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('الحالات الميدانية'), findsOneWidget);
    expect(find.text('شرطة ينبع'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('استيراد بيانات'), findsNothing);
    expect(find.text('الدفعات الواردة'), findsNothing);

    final direction = Directionality.of(
      tester.element(find.byType(Scaffold).first),
    );
    expect(direction, TextDirection.rtl);
  });

  testWidgets('supervisor sees import and inbox', (tester) async {
    await pumpApp(tester, role: UserRole.supervisor);

    expect(find.text('استيراد بيانات'), findsOneWidget);
    expect(find.text('الدفعات الواردة'), findsOneWidget);
    expect(find.text('مشرف'), findsWidgets);
  });

  testWidgets('bottom navigation opens settings', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('الإعدادات').last);
    await tester.pumpAndSettle();

    expect(find.text('اسم الجهة'), findsOneWidget);
    expect(find.text('U-117'), findsOneWidget);
  });

  testWidgets('new case button opens the new case screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
  });

  testWidgets('cases tab searches and filters', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('الحالات').last);
    await tester.pumpAndSettle();

    expect(find.text('جسم صلب'), findsOneWidget);
    expect(find.text('ينبع'), findsOneWidget);

    await tester.tap(find.text('غير مصدرة'));
    await tester.pumpAndSettle();
    expect(find.text('1 حالة مطابقة'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'لا شيء');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد حالات مطابقة'), findsOneWidget);

    await tester.tap(find.text('مسح البحث والفلاتر'));
    await tester.pumpAndSettle();
    expect(find.text('جسم صلب'), findsOneWidget);
  });
}
