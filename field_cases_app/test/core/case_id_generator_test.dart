import 'package:field_cases/core/ids/case_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('display code uses the local date and the first 6 hex digits', () {
    final code = CaseIdGenerator.displayCodeFor(
      'a72f91c4-1b2c-4d5e-8f90-123456789abc',
      DateTime(2026, 9, 25, 19, 30),
    );
    expect(code, 'EVT-20260925-A72F91');
    expect(CaseIdGenerator.displayCodePattern.hasMatch(code), isTrue);
  });

  test('generated ids are unique v4 UUIDs with matching display codes', () {
    final generator = CaseIdGenerator(clock: () => DateTime(2026, 9, 25));
    final ids = List.generate(1000, (_) => generator.next());

    expect(ids.map((i) => i.uuid).toSet(), hasLength(1000));
    for (final identity in ids.take(20)) {
      expect(
        identity.uuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(identity.displayCode, startsWith('EVT-20260925-'));
      expect(
        identity.displayCode.substring(13),
        identity.uuid.substring(0, 6).toUpperCase(),
      );
    }
  });

  test('attachment file names are zero padded and normalized', () {
    expect(
      CaseIdGenerator.attachmentFileName('EVT-20260925-A72F91', 1, '.JPG'),
      'EVT-20260925-A72F91_001.jpg',
    );
    expect(
      CaseIdGenerator.attachmentFileName('EVT-20260925-A72F91', 12, 'png'),
      'EVT-20260925-A72F91_012.png',
    );
  });
}
