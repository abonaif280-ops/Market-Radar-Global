import 'case_enums.dart';
import 'case_views.dart';

/// فلاتر التاريخ السريعة.
enum DatePreset {
  any('كل الأوقات'),
  today('اليوم'),
  week('هذا الأسبوع'),
  custom('فترة محددة');

  const DatePreset(this.label);

  final String label;
}

/// نطاق زمني بالتوقيت المحلي: [from] ضمنه و[to] خارجه.
class DateRange {
  const DateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;
}

/// معايير البحث والتصفية في الحالات.
class CaseQuery {
  const CaseQuery({
    this.text = '',
    this.datePreset = DatePreset.any,
    this.customFrom,
    this.customTo,
    this.exportState,
    this.caseTypeId,
    this.governorateId,
    this.reportSourceId,
  });

  final String text;
  final DatePreset datePreset;

  /// للفترة المحددة: من بداية يوم [customFrom] إلى نهاية يوم [customTo].
  final DateTime? customFrom;
  final DateTime? customTo;
  final ExportState? exportState;
  final String? caseTypeId;
  final String? governorateId;
  final String? reportSourceId;

  bool get isEmpty =>
      text.trim().isEmpty &&
      datePreset == DatePreset.any &&
      exportState == null &&
      caseTypeId == null &&
      governorateId == null &&
      reportSourceId == null;

  /// عدد الفلاتر المتقدمة المفعلة (تظهر على زر "الفلاتر").
  int get advancedFilterCount => [
    caseTypeId,
    governorateId,
    reportSourceId,
    if (datePreset == DatePreset.custom) customFrom,
  ].whereType<Object>().length;

  /// الأسبوع يبدأ يوم الأحد كما هو معتاد في المملكة.
  DateRange? dateRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (datePreset) {
      case DatePreset.any:
        return null;
      case DatePreset.today:
        return DateRange(today, today.add(const Duration(days: 1)));
      case DatePreset.week:
        final daysSinceSunday = today.weekday % 7;
        final start = today.subtract(Duration(days: daysSinceSunday));
        return DateRange(start, start.add(const Duration(days: 7)));
      case DatePreset.custom:
        if (customFrom == null && customTo == null) return null;
        final from = customFrom ?? DateTime(2000);
        final to = customTo ?? today;
        return DateRange(
          DateTime(from.year, from.month, from.day),
          DateTime(to.year, to.month, to.day + 1),
        );
    }
  }

  static const Object _unset = Object();

  CaseQuery copyWith({
    String? text,
    DatePreset? datePreset,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    Object? exportState = _unset,
    Object? caseTypeId = _unset,
    Object? governorateId = _unset,
    Object? reportSourceId = _unset,
  }) {
    return CaseQuery(
      text: text ?? this.text,
      datePreset: datePreset ?? this.datePreset,
      customFrom: identical(customFrom, _unset)
          ? this.customFrom
          : customFrom as DateTime?,
      customTo: identical(customTo, _unset)
          ? this.customTo
          : customTo as DateTime?,
      exportState: identical(exportState, _unset)
          ? this.exportState
          : exportState as ExportState?,
      caseTypeId: identical(caseTypeId, _unset)
          ? this.caseTypeId
          : caseTypeId as String?,
      governorateId: identical(governorateId, _unset)
          ? this.governorateId
          : governorateId as String?,
      reportSourceId: identical(reportSourceId, _unset)
          ? this.reportSourceId
          : reportSourceId as String?,
    );
  }
}

/// مؤشر الصفحة التالية (Keyset Pagination): أداء ثابت مهما كثرت الحالات،
/// بخلاف OFFSET الذي يبطؤ كلما تقدمت الصفحات.
class CaseCursor {
  const CaseCursor(this.occurredAt, this.id);

  final DateTime occurredAt;
  final String id;
}

class CasePage {
  const CasePage(this.items, this.next);

  final List<CaseListItem> items;

  /// null إذا لم تبق صفحات.
  final CaseCursor? next;
}
