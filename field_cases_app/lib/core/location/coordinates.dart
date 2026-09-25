/// إحداثية جغرافية (خط العرض، خط الطول) بدقة 6 خانات عشرية (~10 سم).
class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  static bool isValid(double latitude, double longitude) =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// يقرأ نصًا مثل `24.468245, 39.612354` ويقبل الأرقام العربية والفاصلة العربية.
  ///
  /// يعيد null إذا كان النص غير صالح أو خارج النطاق.
  static Coordinates? tryParse(String input) {
    final normalized = _normalizeDigits(input)
        .replaceAll('،', ',')
        .replaceAll('٫', '.')
        .trim();
    final parts = normalized
        .split(RegExp(r'[,\s]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null || !isValid(lat, lng)) return null;
    return Coordinates(lat, lng);
  }

  /// `24.468245, 39.612354`
  String format() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  static String _normalizeDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      buffer.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is Coordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => format();
}
