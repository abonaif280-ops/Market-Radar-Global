import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// سياسة العمل دون إنترنت: يُمنع إضافة أي حزمة شبكة أو خدمة سحابية/تحليلات.
void main() {
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

  test('pubspec has no network, cloud or analytics dependencies', () {
    final lock = File('pubspec.lock').readAsStringSync();
    final packages = RegExp(
      r'^  ([a-z0-9_]+):$',
      multiLine: true,
    ).allMatches(lock).map((m) => m.group(1)!).toList();

    final offending = packages
        .where(
          (p) =>
              forbiddenExact.contains(p) ||
              forbiddenPrefixes.any((f) => p == f || p.startsWith('${f}_')),
        )
        .toList();
    expect(offending, isEmpty, reason: 'حزم ممنوعة: $offending');
  });

  test('release Android manifest does not request INTERNET', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });
}
