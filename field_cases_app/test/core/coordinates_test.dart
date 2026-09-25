import 'package:field_cases/core/location/coordinates.dart';
import 'package:field_cases/core/platform/map_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coordinates.tryParse', () {
    test('accepts common field formats', () {
      const expected = Coordinates(24.468245, 39.612354);
      for (final input in [
        '24.468245, 39.612354',
        '24.468245,39.612354',
        ' 24.468245   39.612354 ',
        '٢٤٫٤٦٨٢٤٥، ٣٩٫٦١٢٣٥٤',
      ]) {
        expect(Coordinates.tryParse(input), expected, reason: input);
      }
    });

    test('rejects invalid or out-of-range input', () {
      for (final input in ['', 'abc', '24.4', '91, 39', '24, 181', '1, 2, 3']) {
        expect(Coordinates.tryParse(input), isNull, reason: input);
      }
    });

    test('formats with 6 decimals, latitude first', () {
      expect(const Coordinates(24.5, 39.6).format(), '24.500000, 39.600000');
    });
  });

  group('map links', () {
    const c = Coordinates(24.468245, 39.612354);

    test('Android uses a geo: link understood by any maps app', () {
      final uri = SystemMapLauncher.mapUri(c, ios: false);
      expect(uri.scheme, 'geo');
      expect(uri.toString(), startsWith('geo:24.468245,39.612354?q='));
    });

    test('iOS uses the Apple Maps scheme', () {
      final uri = SystemMapLauncher.mapUri(c, label: 'EVT-1', ios: true);
      expect(uri.scheme, 'maps');
      expect(uri.queryParameters['ll'], '24.468245,39.612354');
      expect(uri.queryParameters['q'], 'EVT-1');
    });
  });
}
