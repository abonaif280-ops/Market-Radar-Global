import 'package:field_cases/app/providers.dart';
import 'package:field_cases/app/theme.dart';
import 'package:field_cases/features/import/data/version_resolution_service.dart';
import 'package:field_cases/features/import/presentation/version_compare_screen.dart';
import 'package:field_cases/features/packages/domain/case_diff.dart';
import 'package:field_cases/features/packages/domain/package_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

PackagedCase _case(int revision, {String? notes, bool injuries = false}) =>
    PackagedCase(
      caseUuid: 'c1',
      displayCode: 'EVT-20260925-A72F91',
      serialNo: 3,
      revision: revision,
      contentHash: 'h$revision',
      status: 'completed',
      caseType: const PackagedLookup(code: 'SOLID_OBJECT', label: 'جسم صلب'),
      occurredAt: DateTime(2026, 9, 25, 19, 30),
      originDeviceId: 'DEV-1',
      createdAt: DateTime(2026, 9, 25),
      updatedAt: DateTime(2026, 9, 25),
      governorate: const PackagedLookup(code: 'BADR', label: 'بدر'),
      locationText: 'جنوب مركز الرايس',
      notes: notes,
      hasInjuries: injuries,
      injuriesCount: injuries ? 1 : 0,
      parties: [
        const PackagedLookup(code: 'EOD', label: 'إدارة الأسلحة والمتفجرات'),
        if (injuries)
          const PackagedLookup(code: 'CIVIL_DEF', label: 'الدفاع المدني'),
      ],
    );

class _Versions implements VersionResolutionService {
  final decisions = <VersionChoice>[];

  @override
  Future<VersionComparison> compare(String batchId, String caseId) async {
    final current = _case(1);
    final incoming = _case(
      2,
      notes: 'تحديث: وصول الدفاع المدني',
      injuries: true,
    );
    return VersionComparison(
      current: current,
      incoming: incoming,
      fields: CaseDiff.fields(current, incoming),
      attachments: const AttachmentDiff(added: [], removed: [], unchanged: 2),
    );
  }

  @override
  Future<void> resolve(
    String batchId,
    String caseId,
    VersionChoice choice,
  ) async => decisions.add(choice);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('compare shows changed fields and records the decision', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final versions = _Versions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [versionResolutionProvider.overrideWithValue(versions)],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const VersionCompareScreen(batchId: 'b1', caseId: 'c1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('توجد نسخة أحدث من هذه الحالة'), findsOneWidget);
    expect(find.textContaining('عدد الحقول المختلفة: 3'), findsOneWidget);
    expect(find.text('الإصابات'), findsOneWidget);
    expect(find.text('نعم (1)'), findsOneWidget);
    // الحقول غير المختلفة مخفية افتراضيًا.
    expect(find.text('المحافظة'), findsNothing);

    await tester.tap(find.text('عرض الحقول المختلفة فقط'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('المحافظة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('المحافظة'), findsOneWidget);

    await tester.tap(find.text('الاستبدال بالنسخة الجديدة'));
    await tester.pumpAndSettle();
    expect(find.text('الاستبدال بالنسخة الجديدة؟'), findsOneWidget);
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(versions.decisions, [VersionChoice.replace]);
    expect(find.byType(VersionCompareScreen), findsNothing);
  });
}
