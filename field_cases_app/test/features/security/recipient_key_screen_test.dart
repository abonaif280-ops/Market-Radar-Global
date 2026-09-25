import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/crypto/key_manager.dart';
import 'package:field_cases/features/security/presentation/recipient_key_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeKeys implements KeyManager {
  RecipientKey? saved;

  @override
  Future<RecipientKey?> recipientKey() async => saved;

  @override
  Future<void> setRecipientKey(RecipientKey key) async => saved = key;

  @override
  Future<void> clearRecipientKey() async => saved = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final supervisor = RecipientKey(
    SupervisorPublicKey(List<int>.generate(32, (i) => i * 7 % 256)),
    label: 'مكتب المدير',
  );

  Future<FakeKeys> pump(WidgetTester tester, String? scanned) async {
    final keys = FakeKeys();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyManagerProvider.overrideWithValue(keys),
          keyScannerProvider.overrideWithValue((_) async => scanned),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RecipientKeyScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return keys;
  }

  testWidgets('scanned key is saved only after fingerprint confirmation', (
    tester,
  ) async {
    final keys = await pump(tester, supervisor.toPayload());
    expect(find.text('لم يُضبط مفتاح المشرف'), findsOneWidget);

    await tester.tap(find.text('مسح رمز QR من جوال المشرف'));
    await tester.pumpAndSettle();
    expect(find.text('طابق البصمة مع المشرف'), findsOneWidget);
    expect(find.text(supervisor.fingerprint), findsOneWidget);

    await tester.tap(find.text('غير مطابقة'));
    await tester.pumpAndSettle();
    expect(keys.saved, isNull);

    await tester.tap(find.text('مسح رمز QR من جوال المشرف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('البصمة مطابقة'));
    await tester.pumpAndSettle();
    expect(keys.saved?.fingerprint, supervisor.fingerprint);
    expect(find.textContaining('مكتب المدير'), findsOneWidget);
  });

  testWidgets('invalid QR content is rejected', (tester) async {
    final keys = await pump(tester, 'https://example.com');
    await tester.tap(find.text('مسح رمز QR من جوال المشرف'));
    await tester.pumpAndSettle();
    expect(find.text('الرمز ليس مفتاح مشرف صالحًا'), findsOneWidget);
    expect(keys.saved, isNull);
  });
}
