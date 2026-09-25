import 'package:field_cases/core/utils/arabic_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes Arabic letter variants for search', () {
    expect(ArabicText.normalize('إدارة'), 'اداره');
    expect(ArabicText.normalize('أحمد آل مصطفى'), 'احمد ال مصطفي');
    expect(ArabicText.normalize('مسؤول شاطئ'), 'مسوول شاطي');
  });

  test('removes diacritics and tatweel', () {
    expect(ArabicText.normalize('الشُّرْطَة'), 'الشرطه');
    expect(ArabicText.normalize('حــريـق'), 'حريق');
  });

  test('unifies digits, case and spaces', () {
    expect(ArabicText.normalize('  EVT-٢٠٢٦  ينبع '), 'evt-2026 ينبع');
  });
}
