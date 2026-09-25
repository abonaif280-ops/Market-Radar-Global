/// توحيد النص العربي لأغراض البحث فقط (لا يُعرض للمستخدم):
/// إزالة التشكيل والتطويل، وتوحيد أشكال الألف والياء والتاء المربوطة والهمزات،
/// وتحويل الأرقام العربية إلى إنجليزية، وتصغير الحروف اللاتينية.
///
/// يُطبَّق على النص المخزن في فهرس البحث وعلى نص الاستعلام بنفس الطريقة، فيجد
/// "إدارة" عند البحث بـ "اداره" والعكس.
abstract final class ArabicText {
  static final RegExp _diacritics = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
  static final RegExp _spaces = RegExp(r'\s+');

  static const Map<String, String> _letters = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ى': 'ي',
    'ئ': 'ي',
    'ؤ': 'و',
    'ة': 'ه',
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static String normalize(String input) {
    final stripped = input.replaceAll(_diacritics, '');
    final buffer = StringBuffer();
    for (final rune in stripped.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_letters[ch] ?? ch);
    }
    return buffer.toString().toLowerCase().replaceAll(_spaces, ' ').trim();
  }
}
