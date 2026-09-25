// تُخزَّن هذه القيم في قاعدة البيانات باسم العنصر (enum.name).
// لا تُعِد تسمية أي عنصر بعد اعتماده؛ أضف عناصر جديدة فقط.

/// مرحلة الحالة لدى من أنشأها (الموظف).
enum CaseStatus { draft, completed, ready }

/// مسار المراجعة لدى المشرف للحالات المستوردة.
enum ReviewState { incoming, underReview, approved, rejected }

/// حالة التصدير — مشتقة من revision و lastExportedRevision ولا تُخزَّن.
enum ExportState { notExported, exported, modifiedAfterExport }

/// الحالة الظاهرة للمستخدم بعد دمج المرحلة والتصدير والمراجعة.
enum DisplayStatus {
  draft('مسودة'),
  completed('مكتملة'),
  ready('جاهزة للإرسال'),
  exported('تم التصدير'),
  modifiedAfterExport('تم التعديل بعد التصدير'),
  imported('مستوردة'),
  underReview('تحت المراجعة'),
  approved('معتمدة'),
  rejected('مرفوضة');

  const DisplayStatus(this.label);

  final String label;
}

enum AttachmentKind { image, file }

/// نوع إدخال الحقل الديناميكي الخاص بنوع الحالة.
enum FieldInputType { text, multiline, number, boolean, select, multiSelect }

enum ExportScope { single, selected, unexported, dateRange }

enum ImportBatchStatus { staged, reviewing, completed }

/// تصنيف الحالة الواردة مقارنة بالموجود محليًا.
enum ImportClassification { newCase, duplicate, newer, older, conflict, error }

enum ImportDecision { pending, import, skip, replace, keepBoth }

enum VersionSource { local, import, supervisor }

enum UserRole { employee, supervisor }
