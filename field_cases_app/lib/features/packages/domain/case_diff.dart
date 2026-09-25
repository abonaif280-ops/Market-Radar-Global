import '../../../core/location/coordinates.dart';
import '../../../core/utils/arabic_format.dart';
import 'package_models.dart';

/// فرق حقل واحد بين نسختين من الحالة.
class FieldDiff {
  const FieldDiff(this.label, this.current, this.incoming);

  final String label;
  final String current;
  final String incoming;

  bool get changed => current != incoming;
}

/// فرق الصور بين نسختين (بالمعرف ثم البصمة).
class AttachmentDiff {
  const AttachmentDiff({
    required this.added,
    required this.removed,
    required this.unchanged,
  });

  final List<PackagedAttachment> added;
  final List<PackagedAttachment> removed;
  final int unchanged;

  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty;
}

/// مقارنة نسختين من نفس الحالة حقلًا بحقل لعرضها على المشرف.
abstract final class CaseDiff {
  /// [fieldLabels]: عناوين الحقول الخاصة بالنوع (field_key ← العنوان).
  static List<FieldDiff> fields(
    PackagedCase current,
    PackagedCase incoming, {
    Map<String, String> fieldLabels = const {},
  }) {
    String lookup(PackagedLookup? l) => l?.label ?? '—';
    String text(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();
    String yesNo(bool has, [int? count]) =>
        has ? (count == null ? 'نعم' : 'نعم ($count)') : 'لا';
    String coords(PackagedCase c) => c.latitude == null || c.longitude == null
        ? '—'
        : Coordinates(c.latitude!, c.longitude!).format();
    String extra(Object? v) => switch (v) {
      null => '—',
      true => 'نعم',
      false => 'لا',
      final List<Object?> l => l.isEmpty ? '—' : l.join('، '),
      final String s when s.trim().isEmpty => '—',
      _ => '$v',
    };

    final diffs = <FieldDiff>[
      FieldDiff(
        'نوع الحالة',
        lookup(current.caseType),
        lookup(incoming.caseType),
      ),
      FieldDiff(
        'التاريخ والوقت',
        ArabicFormat.dateTime(current.occurredAt),
        ArabicFormat.dateTime(incoming.occurredAt),
      ),
      FieldDiff(
        'مصدر البلاغ',
        lookup(current.reportSource),
        lookup(incoming.reportSource),
      ),
      FieldDiff(
        'المحافظة',
        lookup(current.governorate),
        lookup(incoming.governorate),
      ),
      FieldDiff('المركز', lookup(current.center), lookup(incoming.center)),
      FieldDiff(
        'الموقع',
        text(current.locationText),
        text(incoming.locationText),
      ),
      FieldDiff(
        'وصف الموقع',
        text(current.locationDescription),
        text(incoming.locationDescription),
      ),
      FieldDiff('الإحداثيات', coords(current), coords(incoming)),
      FieldDiff(
        'معلومات الحالة',
        text(current.caseInfo),
        text(incoming.caseInfo),
      ),
      FieldDiff(
        'الإجراء المتخذ',
        text(current.actionTaken),
        text(incoming.actionTaken),
      ),
      FieldDiff(
        'الإصابات',
        yesNo(current.hasInjuries, current.injuriesCount),
        yesNo(incoming.hasInjuries, incoming.injuriesCount),
      ),
      FieldDiff(
        'الوفيات',
        yesNo(current.hasDeaths, current.deathsCount),
        yesNo(incoming.hasDeaths, incoming.deathsCount),
      ),
      FieldDiff(
        'الأضرار',
        current.hasDamage ? 'نعم — ${text(current.damageDescription)}' : 'لا',
        incoming.hasDamage ? 'نعم — ${text(incoming.damageDescription)}' : 'لا',
      ),
      FieldDiff(
        'الجهات المباشرة',
        _joinLabels(current.parties),
        _joinLabels(incoming.parties),
      ),
    ];

    final keys = {
      ...current.extraFields.keys,
      ...incoming.extraFields.keys,
    }.toList()..sort();
    for (final key in keys) {
      diffs.add(
        FieldDiff(
          fieldLabels[key] ?? key,
          extra(current.extraFields[key]),
          extra(incoming.extraFields[key]),
        ),
      );
    }
    diffs
      ..add(FieldDiff('ملاحظات', text(current.notes), text(incoming.notes)))
      ..add(
        FieldDiff(
          'نص الحالة',
          text(current.finalText),
          text(incoming.finalText),
        ),
      );
    return diffs;
  }

  static AttachmentDiff attachments(
    PackagedCase current,
    PackagedCase incoming,
  ) {
    bool same(PackagedAttachment a, PackagedAttachment b) =>
        a.attachmentUuid == b.attachmentUuid || a.sha256 == b.sha256;
    final added = [
      for (final a in incoming.attachments)
        if (!current.attachments.any((c) => same(c, a))) a,
    ];
    final removed = [
      for (final c in current.attachments)
        if (!incoming.attachments.any((a) => same(c, a))) c,
    ];
    return AttachmentDiff(
      added: added,
      removed: removed,
      unchanged: incoming.attachments.length - added.length,
    );
  }

  static String _joinLabels(List<PackagedLookup> items) {
    if (items.isEmpty) return '—';
    final labels = items.map((p) => p.label).toList()..sort();
    return labels.join('، ');
  }
}
