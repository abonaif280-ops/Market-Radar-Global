import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/security/pin_attempt_guard.dart';
import 'package:field_cases/features/security/data/app_lock_service.dart';
import 'package:field_cases/features/security/presentation/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLock implements AppLockService {
  FakeLock({this.enabled = true, this.biometric = false});

  bool enabled;
  bool biometric;
  bool biometricResult = false;
  final guard = PinAttemptGuard();

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Stream<bool> watchEnabled() => Stream.value(enabled);

  @override
  Future<bool> biometricEnabled() async => biometric;

  @override
  Future<bool> unlockWithBiometric() async => biometric && biometricResult;

  @override
  Future<PinCheck> verifyPin(String pin) =>
      guard.check(() async => pin == '123456');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late DateTime now;

  Future<void> pumpGate(WidgetTester tester, FakeLock lock) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockServiceProvider.overrideWithValue(lock)],
        child: MaterialApp(
          locale: const Locale('ar'),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: AppLockGate(clock: () => now, child: child!),
          ),
          home: const Scaffold(body: Center(child: Text('بيانات سرية'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  bool contentHittable(WidgetTester tester) =>
      find.text('بيانات سرية').hitTestable().evaluate().isNotEmpty;

  setUp(() => now = DateTime(2026, 9, 25, 10));

  testWidgets('no lock screen when app lock is off', (tester) async {
    await pumpGate(tester, FakeLock(enabled: false));
    expect(find.text('التطبيق مقفل'), findsNothing);
    expect(contentHittable(tester), isTrue);
  });

  testWidgets('locked on start; wrong PIN rejected, right PIN unlocks', (
    tester,
  ) async {
    await pumpGate(tester, FakeLock());
    expect(find.text('التطبيق مقفل'), findsOneWidget);
    expect(contentHittable(tester), isFalse);

    await typePin(tester, '000000');
    expect(find.textContaining('رمز خاطئ'), findsOneWidget);
    expect(find.text('التطبيق مقفل'), findsOneWidget);

    await typePin(tester, '123456');
    expect(find.text('التطبيق مقفل'), findsNothing);
    expect(contentHittable(tester), isTrue);
  });

  testWidgets('biometric success unlocks automatically', (tester) async {
    await pumpGate(tester, FakeLock(biometric: true)..biometricResult = true);
    expect(find.text('التطبيق مقفل'), findsNothing);
  });

  testWidgets('re-locks only after a minute in the background', (tester) async {
    final lock = FakeLock();
    await pumpGate(tester, lock);
    await typePin(tester, '123456');
    expect(find.text('التطبيق مقفل'), findsNothing);

    Future<void> background(Duration away) async {
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      // المحتوى مغطى فور مغادرة التطبيق (معاينة التطبيقات المفتوحة).
      expect(contentHittable(tester), isFalse);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(away);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    await background(const Duration(seconds: 20));
    expect(find.text('التطبيق مقفل'), findsNothing);
    expect(contentHittable(tester), isTrue);

    await background(const Duration(minutes: 2));
    expect(find.text('التطبيق مقفل'), findsOneWidget);
  });
}
