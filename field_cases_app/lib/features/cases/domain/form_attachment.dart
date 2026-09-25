/// صورة/مرفق داخل نموذج الحالة: إما مرفق محفوظ مسبقًا، أو صورة جديدة في منطقة الانتظار
/// (staging) لم تُربط بالحالة بعد. الربط الفعلي يتم عند الحفظ فقط.
class FormAttachment {
  const FormAttachment({
    this.id,
    required this.filePath,
    required this.thumbPath,
    required this.sha256,
    required this.sizeBytes,
    required this.mimeType,
    this.width,
    this.height,
    this.fileName,
  });

  /// معرف المرفق المحفوظ؛ null لصورة جديدة لم تُحفظ بعد.
  final String? id;

  /// المسار المطلق للملف (النهائي أو في منطقة الانتظار).
  final String filePath;

  /// المسار المطلق للصورة المصغرة؛ null إذا تعذر إنشاؤها (مثل HEIC).
  final String? thumbPath;
  final String sha256;
  final int sizeBytes;
  final String mimeType;
  final int? width;
  final int? height;

  /// الاسم المنظم (`EVT-..._001.jpg`) للمرفقات المحفوظة.
  final String? fileName;

  bool get isNew => id == null;

  /// الصورة المستخدمة في القوائم: المصغرة إن وجدت.
  String get previewPath => thumbPath ?? filePath;
}
