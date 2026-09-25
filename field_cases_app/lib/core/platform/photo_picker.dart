import 'package:image_picker/image_picker.dart';

/// التصوير أو الاختيار من المعرض. يعيد مسارات ملفات مؤقتة يستوردها التطبيق لمساحته الخاصة.
abstract interface class PhotoPicker {
  Future<String?> takePhoto();

  Future<List<String>> pickFromGallery();
}

class SystemPhotoPicker implements PhotoPicker {
  SystemPhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// ضغط أصلي في النظام: يكفي لقراءة التفاصيل ويخفف حجم الحزم المرسلة.
  static const double maxDimension = 2560;
  static const int quality = 85;

  final ImagePicker _picker;

  @override
  Future<String?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: quality,
      requestFullMetadata: false,
    );
    return file?.path;
  }

  @override
  Future<List<String>> pickFromGallery() async {
    final files = await _picker.pickMultiImage(
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: quality,
      requestFullMetadata: false,
    );
    return files.map((f) => f.path).toList();
  }
}
