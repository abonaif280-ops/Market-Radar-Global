import 'package:field_cases/app/providers.dart';
import 'package:field_cases/features/trash/data/trash_repository.dart';
import 'package:field_cases/features/trash/presentation/trash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTrash implements TrashRepository {
  final restored = <String>[];
  final purged = <String>[];
  var purgedAll = false;

  @override
  Future<void> restore(String caseId) async => restored.add(caseId);

  @override
  Future<PurgeResult> purge(String caseId) async {
    purged.add(caseId);
    return const PurgeResult(cases: 1, files: 2);
  }

  @override
  Future<PurgeResult> purgeAll() async {
    purgedAll = true;
    return const PurgeResult(cases: 2, files: 3);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final items = [
    DeletedCase(
      id: 'c1',
      displayCode: 'EVT-20260925-A1',
      caseTypeLabel: 'جسم صلب',
      occurredAt: DateTime(2026, 9, 25, 8),
      deletedAt: DateTime(2026, 9, 25, 9),
      photoCount: 2,
    ),
    DeletedCase(
      id: 'c2',
      displayCode: 'EVT-20260925-B2',
      caseTypeLabel: 'حريق',
      occurredAt: DateTime(2026, 9, 24, 8),
      deletedAt: DateTime(2026, 9, 24, 9),
      photoCount: 0,
    ),
  ];

  Future<FakeTrash> pump(WidgetTester tester) async {
    final trash = FakeTrash();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trashRepositoryProvider.overrideWithValue(trash),
          deletedCasesProvider.overrideWith((ref) => Stream.value(items)),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: TrashScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return trash;
  }

  testWidgets('restore is one tap; permanent delete needs confirmation', (
    tester,
  ) async {
    final trash = await pump(tester);
    expect(find.text('جسم صلب'), findsOneWidget);
    expect(find.textContaining('EVT-20260925-A1'), findsOneWidget);

    await tester.tap(find.text('استعادة').first);
    await tester.pumpAndSettle();
    expect(trash.restored, ['c1']);

    await tester.tap(find.text('حذف نهائي').first);
    await tester.pumpAndSettle();
    expect(find.text('حذف نهائي؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(trash.purged, isEmpty);

    await tester.tap(find.text('حذف نهائي').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حذف نهائي'));
    await tester.pumpAndSettle();
    expect(trash.purged, ['c1']);
  });

  testWidgets('empty trash asks first', (tester) async {
    final trash = await pump(tester);
    await tester.tap(find.text('إفراغ'));
    await tester.pumpAndSettle();
    expect(find.text('إفراغ المحذوفات؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إفراغ'));
    await tester.pumpAndSettle();
    expect(trash.purgedAll, isTrue);
  });
}
