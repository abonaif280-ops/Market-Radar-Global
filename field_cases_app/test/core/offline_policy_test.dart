import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// سياسة العمل دون إنترنت: يُمنع إضافة أي حزمة شبكة أو خدمة سحابية/تحليلات.
// عملاء HTTP بالاسم الدقيق (http_parser مثلًا أداة تحليل وليست عميلًا).
const forbiddenExact = ['http', 'dio', 'chopper', 'retrofit', 'google_fonts'];
const forbiddenPrefixes = [
  'firebase',
  'cloud_firestore',
  'supabase',
  'sentry',
  'amplitude',
  'mixpanel',
  'appsflyer',
  'google_mobile_ads',
];

void main() {
  test('no direct network/cloud/analytics dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final direct = RegExp(
      r'^  ([a-z0-9_]+):',
      multiLine: true,
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();
    final offending = direct.where(_isForbidden).toList();
    expect(offending, isEmpty, reason: 'حزم ممنوعة مباشرة: $offending');
  });

  test('no cloud or analytics SDK anywhere in the dependency tree', () {
    // عملاء HTTP قد يظهرون تبعيات غير مباشرة لنسخ الويب (مثل image_picker)؛
    // أما حزم السحابة والتحليلات فممنوعة في الشجرة كلها.
    final lock = File('pubspec.lock').readAsStringSync();
    final packages = RegExp(
      r'^  ([a-z0-9_]+):$',
      multiLine: true,
    ).allMatches(lock).map((m) => m.group(1)!);
    final offending = packages
        .where(
          (p) => forbiddenPrefixes.any((f) => p == f || p.startsWith('${f}_')),
        )
        .toList();
    expect(offending, isEmpty, reason: 'حزم ممنوعة: $offending');
  });

  test('app code makes no network calls', () {
    final patterns = [
      RegExp(r"package:(http|dio)/"),
      RegExp(r'\bHttpClient\b'),
      RegExp(r'\b(Raw)?Socket\.connect\b'),
      RegExp(r'\bWebSocket\b'),
    ];
    final offending = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (patterns.any((p) => p.hasMatch(source))) offending.add(file.path);
    }
    expect(offending, isEmpty, reason: 'اتصال شبكي في: $offending');
  });

  test(
    'release Android manifest strips INTERNET and disables cloud backup',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(
        manifest,
        contains(
          '<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>',
        ),
      );
      expect(manifest, contains('android:allowBackup="false"'));
    },
  );
}

bool _isForbidden(String p) =>
    forbiddenExact.contains(p) ||
    forbiddenPrefixes.any((f) => p == f || p.startsWith('${f}_'));
