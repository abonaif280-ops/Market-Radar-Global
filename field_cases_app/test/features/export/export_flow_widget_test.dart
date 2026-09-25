import 'dart:io';

import 'package:field_cases/app/app.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/platform/share_service.dart';
import 'package:field_cases/features/cases/data/cases_repository.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_query.dart';
import 'package:field_cases/features/cases/domain/case_views.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:field_cases/features/packages/domain/package_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Cases implements CasesRepository {
  final items = [
    for (final (i, label) in [(1, 'جسم صلب'), (2, 'حريق'), (3, 'شظايا')])
      CaseListItem(
        id: 'c$i',
        displayCode: 'EVT-$i',
        serialNo: i,
        occurredAt: DateTime.now().subtract(Duration(minutes: i)),
        caseTypeLabel: label,
        placeLabel: 'ينبع',
        displayStatus: DisplayStatus.completed,
      ),
  ];

  @override
  Future<CasePage> searchCases(
    CaseQuery q, {
    CaseCursor? after,
    int limit = 30,
  }) async => CasePage(items, null);
  @override
  Future<int> countCases(CaseQuery q) async => items.length;
  @override
  Stream<void> watchChanges() => const Stream.empty();
  @override
  Stream<int> watchTodayCount() => Stream.value(0);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Exporter implements CaseExportService {
  final exported = <ExportRequest>[];

  @override
  Future<ExportPreview> preview(ExportRequest request) async => ExportPreview(
    caseIds: request.scope == ExportScope.unexported
        ? const ['c1', 'c2', 'c3']
        : request.explicitIds,
    imageCount: 4,
    totalBytes: 3 * 1024 * 1024,
  );

  @override
  Future<ExportResult> export(ExportRequest request) async {
    exported.add(request);
    return ExportResult(
      file: File('/tmp/شرطة_ينبع_20260925_1930.casepkg'),
      sizeBytes: 3 * 1024 * 1024,
      manifest: PackageManifest(
        packageFormatVersion: 1,
        packageId: 'p1',
        createdAt: DateTime(2026, 9, 25),
        createdAtLocal: null,
        appVersion: '1.0.0+1',
        source: const PackageSource(deviceId: 'DEV-1'),
        scope: request.scope.name,
        caseCount: request.explicitIds.length,
        imageCount: 4,
        attachmentCount: 4,
        files: const [],
        contentSha256: 'x',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Share implements ShareService {
  final files = <String>[];
  @override
  Future<void> shareFile(String path, {String? text}) async => files.add(path);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('select cases, export and share the package', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final exporter = _Exporter();
    final share = _Share();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesRepositoryProvider.overrideWithValue(_Cases()),
          caseExportServiceProvider.overrideWithValue(exporter),
          shareServiceProvider.overrideWithValue(share),
          userRoleProvider.overrideWith(
            (ref) => Stream.value(UserRole.employee),
          ),
          orgNameProvider.overrideWith((ref) => Stream.value('شرطة ينبع')),
        ],
        child: const FieldCasesApp(),
      ),
    );
    await tester.pumpAndSettle();

    // الرئيسية ← التصدير
    await tester.tap(find.text('التصدير'));
    await tester.pumpAndSettle();
    expect(find.text('جميع الحالات غير المصدرة'), findsOneWidget);
    expect(find.textContaining('3 حالة'), findsOneWidget);

    // اختيار يدوي
    await tester.tap(find.text('اختيار حالات يدويًا'));
    await tester.pumpAndSettle();
    expect(find.text('تصدير المحدد (0)'), findsOneWidget);
    await tester.tap(find.text('جسم صلب'));
    await tester.tap(find.text('شظايا'));
    await tester.pumpAndSettle();
    expect(find.text('تصدير المحدد (2)'), findsOneWidget);

    await tester.tap(find.text('تصدير المحدد (2)'));
    await tester.pumpAndSettle();
    expect(find.text('إنشاء حزمة التصدير'), findsOneWidget);
    expect(find.text('3.0 م.ب'), findsOneWidget);

    await tester.tap(find.text('إنشاء الحزمة'));
    await tester.pumpAndSettle();
    expect(exporter.exported.single.explicitIds, ['c1', 'c3']);
    expect(find.text('أُنشئت الحزمة'), findsOneWidget);
    expect(find.textContaining('20260925_1930.casepkg'), findsOneWidget);

    await tester.tap(find.text('مشاركة الملف'));
    await tester.pumpAndSettle();
    expect(share.files.single, endsWith('.casepkg'));

    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    // بعد التصدير يعود لشاشة التصدير.
    expect(find.text('جميع الحالات غير المصدرة'), findsOneWidget);
  });
}
