import 'package:uuid/uuid.dart';

/// معرف الحالة: UUID كامل داخليًا + رمز ظاهر مختصر للمستخدم.
class CaseIdentity {
  const CaseIdentity({required this.uuid, required this.displayCode});

  final String uuid;
  final String displayCode;
}

/// يولد معرفات الحالات بصيغة `EVT-YYYYMMDD-XXXXXX`.
///
/// الرمز الظاهر للعرض فقط وقد يتكرر نظريًا بين أجهزة مختلفة؛
/// منع التكرار والربط يعتمدان دائمًا على [CaseIdentity.uuid].
class CaseIdGenerator {
  CaseIdGenerator({Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  static const String prefix = 'EVT';
  static final RegExp displayCodePattern = RegExp(r'^EVT-\d{8}-[0-9A-F]{6}$');

  final Uuid _uuid;
  final DateTime Function() _clock;

  CaseIdentity next() {
    final id = _uuid.v4();
    return CaseIdentity(uuid: id, displayCode: displayCodeFor(id, _clock()));
  }

  static String displayCodeFor(String uuid, DateTime localTime) {
    final local = localTime.toLocal();
    final datePart =
        '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}';
    final hexPart = uuid.replaceAll('-', '').substring(0, 6).toUpperCase();
    return '$prefix-$datePart-$hexPart';
  }

  /// اسم ملف المرفق المنظم: `EVT-20260925-A72F91_001.jpg`.
  static String attachmentFileName(
    String displayCode,
    int sequence,
    String extension,
  ) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final seq = sequence.toString().padLeft(3, '0');
    return '${displayCode}_$seq.${ext.toLowerCase()}';
  }
}
