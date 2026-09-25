/// تنسيق التاريخ والوقت بالعربية مع أرقام إنجليزية (كما في المخاطبات الميدانية).
///
/// لا يعتمد على بيانات intl المحلية حتى يعمل مباشرة في الاختبارات وفي القوالب.
abstract final class ArabicFormat {
  static const List<String> _weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// `7:30 مساءً`
  static String time(DateTime value) {
    final local = value.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'صباحًا' : 'مساءً';
    return '$hour12:$minute $period';
  }

  /// `14:35`
  static String time24(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// `25/09/2026`
  static String date(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year}';
  }

  /// `الخميس 25/09/2026`
  static String weekdayDate(DateTime value) {
    final local = value.toLocal();
    return '${_weekdays[local.weekday - 1]} ${date(local)}';
  }

  /// `25/09/2026 - 7:30 مساءً`
  static String dateTime(DateTime value) => '${date(value)} - ${time(value)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
