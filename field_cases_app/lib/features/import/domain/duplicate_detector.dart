import '../../cases/domain/case_enums.dart';

/// ما يلزم من الحالة الموجودة محليًا للمقارنة.
class ExistingCaseSnapshot {
  const ExistingCaseSnapshot({
    required this.revision,
    required this.contentHash,
  });

  final int revision;
  final String? contentHash;
}

/// تصنيف الحالة الواردة (docs/DESIGN.md البند 12). المفتاح دائمًا case_uuid
/// وليس اسم الملف ولا الرقم الظاهر.
abstract final class DuplicateDetector {
  static ImportClassification classify({
    required int incomingRevision,
    required String incomingHash,
    ExistingCaseSnapshot? existing,
  }) {
    if (existing == null) return ImportClassification.newCase;
    if (existing.contentHash == incomingHash) {
      return ImportClassification.duplicate;
    }
    if (incomingRevision > existing.revision) {
      return ImportClassification.newer;
    }
    if (incomingRevision < existing.revision) {
      return ImportClassification.older;
    }
    return ImportClassification.conflict;
  }

  /// القرار الافتراضي: الجديدة تُستورد، المكررة والأقدم تُتجاهل،
  /// والأحدث والمتعارضة تنتظر قرار المشرف (مقارنة الإصدارات).
  static ImportDecision defaultDecision(ImportClassification c) => switch (c) {
    ImportClassification.newCase => ImportDecision.import,
    ImportClassification.duplicate ||
    ImportClassification.older ||
    ImportClassification.error => ImportDecision.skip,
    ImportClassification.newer ||
    ImportClassification.conflict => ImportDecision.pending,
  };

  static String label(ImportClassification c) => switch (c) {
    ImportClassification.newCase => 'جديدة',
    ImportClassification.duplicate => 'موجودة مسبقًا',
    ImportClassification.newer => 'نسخة أحدث',
    ImportClassification.older => 'نسخة أقدم',
    ImportClassification.conflict => 'نسخة مختلفة',
    ImportClassification.error => 'خطأ',
  };
}
