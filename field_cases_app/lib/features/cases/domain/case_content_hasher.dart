import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'case_form_data.dart';

/// بصمة SHA-256 لمحتوى الحالة بتمثيل JSON موحّد (مفاتيح مرتبة).
///
/// تُستخدم لاكتشاف: هل تغيّر المحتوى فعلًا (لرفع revision)، وهل الحالة الواردة
/// مطابقة للموجودة عند الاستيراد. لا تدخل فيها الحقول المحلية مثل status والتواريخ الإدارية.
class CaseContentHasher {
  const CaseContentHasher._();

  /// بصمات الصور بترتيبها جزء من المحتوى: إضافة صورة أو حذفها تُعد تعديلًا.
  static String hash(CaseFormData data) {
    final content = <String, Object?>{
      'case_type_id': data.caseTypeId,
      'occurred_at': data.occurredAt.toUtc().toIso8601String(),
      'governorate_id': data.governorateId,
      'center_id': data.centerId,
      'location_text': data.locationText.trim(),
      'report_source_id': data.reportSourceId,
      'location_description': data.locationDescription.trim(),
      'latitude': data.latitude?.toStringAsFixed(6),
      'longitude': data.longitude?.toStringAsFixed(6),
      'case_info': data.caseInfo.trim(),
      'action_taken': data.actionTaken.trim(),
      'injuries': data.hasInjuries ? data.injuriesCount : 0,
      'deaths': data.hasDeaths ? data.deathsCount : 0,
      'damage': data.hasDamage ? data.damageDescription.trim() : null,
      'notes': data.notes.trim(),
      'extra_fields': data.extraFields,
      'party_ids': data.partyIds.toList()..sort(),
      'final_text': data.finalText?.trim(),
      'attachments': [for (final a in data.attachments) a.sha256],
    };
    final canonical = jsonEncode(_canonicalize(content));
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _canonicalize(value[k])};
    }
    if (value is List) return value.map(_canonicalize).toList();
    if (value is Set) {
      return (value.map((e) => e.toString()).toList()..sort());
    }
    return value;
  }
}
