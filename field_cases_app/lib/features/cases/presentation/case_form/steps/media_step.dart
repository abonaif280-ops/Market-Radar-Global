import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';
import '../../../../../core/files/attachment_storage.dart';
import '../../../../../core/location/coordinates.dart';
import '../../../../../core/location/location_service.dart';
import '../../../domain/case_form_data.dart';
import '../../../domain/form_attachment.dart';
import '../../widgets/coordinates_actions.dart';
import '../../widgets/photo_grid.dart';

/// الخطوة 4: الإحداثيات والصور.
class MediaStep extends ConsumerStatefulWidget {
  const MediaStep({super.key, required this.data, required this.onChanged});

  final CaseFormData data;
  final VoidCallback onChanged;

  @override
  ConsumerState<MediaStep> createState() => _MediaStepState();
}

class _MediaStepState extends ConsumerState<MediaStep> {
  bool _locating = false;
  int _importing = 0;
  double? _accuracy;

  CaseFormData get _data => widget.data;

  Coordinates? get _coordinates =>
      _data.latitude == null || _data.longitude == null
      ? null
      : Coordinates(_data.latitude!, _data.longitude!);

  void _setCoordinates(Coordinates? c) {
    _data
      ..latitude = c?.latitude
      ..longitude = c?.longitude;
    widget.onChanged();
  }

  void _show(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    final service = ref.read(locationServiceProvider);
    final result = await service.currentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case LocationSuccess(:final coordinates, :final accuracyMeters):
        setState(() => _accuracy = accuracyMeters);
        _setCoordinates(coordinates);
      case LocationFailure(:final reason):
        _show(
          result.message,
          action: reason == LocationFailureReason.permanentlyDenied
              ? SnackBarAction(
                  label: 'الإعدادات',
                  onPressed: service.openSystemSettings,
                )
              : null,
        );
    }
  }

  Future<void> _editManually() async {
    final entered = await showDialog<Coordinates>(
      context: context,
      builder: (_) => _ManualCoordinatesDialog(initial: _coordinates),
    );
    if (entered == null) return;
    setState(() => _accuracy = null);
    _setCoordinates(entered);
  }

  Future<void> _addPhotos({required bool camera}) async {
    final picker = ref.read(photoPickerProvider);
    final storage = ref.read(attachmentStorageProvider);
    final List<String> paths;
    try {
      if (camera) {
        final path = await picker.takePhoto();
        paths = path == null ? const [] : [path];
      } else {
        paths = await picker.pickFromGallery();
      }
    } on Exception catch (e) {
      _show('تعذر فتح ${camera ? 'الكاميرا' : 'المعرض'}: $e');
      return;
    }
    if (paths.isEmpty || !mounted) return;

    setState(() => _importing += paths.length);
    for (final path in paths) {
      try {
        // ملفات image_picker نسخ مؤقتة؛ تُحذف بعد نسخها لمساحة التطبيق الخاصة.
        final staged = await storage.stageImage(path, deleteSource: true);
        if (!mounted) {
          await storage.discardStaged([staged]);
          return;
        }
        _data.attachments.add(staged);
        widget.onChanged();
      } on AttachmentStorageException catch (e) {
        _show(e.message);
      } on Exception catch (e) {
        _show('تعذر إضافة الصورة: $e');
      } finally {
        if (mounted) setState(() => _importing--);
      }
    }
  }

  Future<void> _removePhoto(FormAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة؟'),
        content: Text(
          attachment.isNew
              ? 'ستُحذف الصورة من هذه الحالة.'
              : 'ستُحذف الصورة من الحالة عند حفظ التعديلات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _data.attachments.remove(attachment);
    widget.onChanged();
    if (attachment.isNew) {
      await ref.read(attachmentStorageProvider).discardStaged([attachment]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = _coordinates;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('الإحداثيات'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _locating ? null : _captureLocation,
                  icon: _locating
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _locating ? 'جارٍ تحديد الموقع…' : 'التقاط الموقع الحالي',
                  ),
                ),
                const SizedBox(height: 12),
                if (coordinates != null) ...[
                  SelectableText(
                    coordinates.format(),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_accuracy != null)
                    Text(
                      'الدقة التقريبية ${_accuracy!.round()} م',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 12),
                  CoordinatesActions(coordinates: coordinates),
                  const SizedBox(height: 4),
                ] else
                  Text(
                    'لم تُضف إحداثيات',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _editManually,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text(
                        coordinates == null ? 'إدخال يدوي' : 'تعديل يدوي',
                      ),
                    ),
                    if (coordinates != null)
                      TextButton.icon(
                        onPressed: () => _setCoordinates(null),
                        icon: const Icon(Icons.location_off_outlined),
                        label: const Text('إزالة'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle('الصور (${_data.attachments.length})'),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                ),
                onPressed: () => _addPhotos(camera: true),
                icon: const Icon(Icons.photo_camera, size: 26),
                label: const Text('الكاميرا'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                ),
                onPressed: () => _addPhotos(camera: false),
                icon: const Icon(Icons.photo_library, size: 26),
                label: const Text('المعرض'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_importing > 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (_data.attachments.isEmpty && _importing == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'الصور تُحفظ داخل التطبيق فقط ولا تظهر في معرض الجهاز.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          PhotoGrid(attachments: _data.attachments, onRemove: _removePhoto),
      ],
    );
  }
}

class _ManualCoordinatesDialog extends StatefulWidget {
  const _ManualCoordinatesDialog({this.initial});

  final Coordinates? initial;

  @override
  State<_ManualCoordinatesDialog> createState() =>
      _ManualCoordinatesDialogState();
}

class _ManualCoordinatesDialogState extends State<_ManualCoordinatesDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.format(),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = Coordinates.tryParse(_controller.text);
    if (parsed == null) {
      setState(
        () => _error = 'الصيغة: خط العرض، خط الطول — مثل 24.468245, 39.612354',
      );
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إدخال الإحداثية'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textDirection: TextDirection.ltr,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          hintText: '24.468245, 39.612354',
          errorText: _error,
          errorMaxLines: 2,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
