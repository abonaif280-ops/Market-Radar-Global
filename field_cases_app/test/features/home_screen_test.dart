import 'package:field_cases/app/app.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
          recentCasesProvider.overrideWith((ref) => Stream.value(const [])),
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

    expect(find.text('الخطوة 1 من 4'), findsOneWidget);
  });
}
