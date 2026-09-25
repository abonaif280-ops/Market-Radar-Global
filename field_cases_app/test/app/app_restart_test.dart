import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:field_cases/app/app_restart.dart';
import 'package:field_cases/app/providers.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    return MaterialApp(home: Text('db:${identityHashCode(db)}'));
  }
}

/// يدفع الإطارات والوقت الحقيقي حتى تكتمل العملية (إغلاق القاعدة غير متزامن).
Future<void> _drive(WidgetTester tester, Future<void> operation) async {
  var done = false;
  Object? failure;
  operation.then(
    (_) => done = true,
    onError: (Object e) {
      failure = e;
      done = true;
    },
  );
  for (var i = 0; i < 100 && !done; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  if (failure != null) throw failure!;
  expect(done, isTrue, reason: 'restart did not finish');
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  ProviderContainer containerWith(AppDatabase db) =>
      ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);

  testWidgets('restart closes the database, runs the swap, then reopens', (
    tester,
  ) async {
    final first = AppDatabase(NativeDatabase.memory());
    final second = AppDatabase(NativeDatabase.memory());
    addTearDown(second.close);
    final controller = AppRestartController();
    await tester.pumpWidget(
      AppRoot(
        controller: controller,
        initial: containerWith(first),
        bootstrap: () async => containerWith(second),
        app: const _Probe(),
      ),
    );
    expect(find.text('db:${identityHashCode(first)}'), findsOneWidget);

    var swapped = false;
    Object? reportedError = 'unset';
    ProviderContainer? reopened;
    await _drive(
      tester,
      controller.restart(
        whileClosed: () async {
          swapped = true;
        },
        afterReopen: (container, error) async {
          reopened = container;
          reportedError = error;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(reportedError, isNull);
    expect(swapped, isTrue);
    expect(reportedError, isNull);
    expect(reopened!.read(appDatabaseProvider), same(second));
    expect(find.text('db:${identityHashCode(second)}'), findsOneWidget);
  });

  testWidgets('a failed swap still reopens and reports the error', (
    tester,
  ) async {
    final first = AppDatabase(NativeDatabase.memory());
    final second = AppDatabase(NativeDatabase.memory());
    addTearDown(second.close);
    final controller = AppRestartController();
    await tester.pumpWidget(
      AppRoot(
        controller: controller,
        initial: containerWith(first),
        bootstrap: () async => containerWith(second),
        app: const _Probe(),
      ),
    );
    Object? reportedError;
    await _drive(
      tester,
      controller.restart(
        whileClosed: () async => throw StateError('disk full'),
        afterReopen: (_, error) async => reportedError = error,
      ),
    );
    await tester.pumpAndSettle();
    expect(reportedError, isA<StateError>());
    expect(find.text('db:${identityHashCode(second)}'), findsOneWidget);
  });
}
