import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/app_database.dart';
import '../../cases/domain/case_enums.dart';
import '../../cases/domain/case_form_data.dart';
import '../../cases/domain/case_type_field.dart';
import '../data/case_text_composer.dart';
import '../domain/case_template_variables.dart';
import '../domain/template_engine.dart';

/// تعديل قالب: إدراج المتغيرات بضغطة، والتحقق من البنية، ومعاينة فورية ببيانات مثال.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, required this.templateId});

  final String templateId;

  static Future<void> open(BuildContext context, String templateId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateEditorScreen(templateId: templateId),
      ),
    );
  }

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _controller = TextEditingController();
  TextTemplate? _template;
  List<CaseTypeFieldDef> _fields = const [];
  String? _caseTypeLabel;
  String _savedBody = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final template = await ref
        .read(templateRepositoryProvider)
        .byId(widget.templateId);
    if (template == null || !mounted) return;
    final fields = template.caseTypeId == null
        ? const <CaseTypeFieldDef>[]
        : await ref
              .read(lookupRepositoryProvider)
              .fieldsForType(template.caseTypeId!);
    final typeLabel = template.caseTypeId == null
        ? null
        : (await ref.read(lookupRepositoryProvider).byId(template.caseTypeId!))
              ?.label;
    if (!mounted) return;
    setState(() {
      _template = template;
      _fields = fields;
      _caseTypeLabel = typeLabel;
      _savedBody = template.body;
      _controller.text = template.body;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(String tag) {
    final value = _controller.value;
    final start = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final end = value.selection.isValid ? value.selection.end : start;
    final text = value.text.replaceRange(start, end, tag);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
    setState(() {});
  }

  Future<void> _save() async {
    await ref
        .read(templateRepositoryProvider)
        .updateBody(widget.templateId, _controller.text);
    if (!mounted) return;
    setState(() => _savedBody = _controller.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('حُفظ القالب')));
  }

  Future<void> _restoreDefault() async {
    final body = ref
        .read(templateRepositoryProvider)
        .defaultBodyFor(_template!);
    if (body == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة القالب الافتراضي؟'),
        content: const Text('سيُستبدل النص الحالي بالقالب الأصلي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _controller.text = body;
    setState(() {});
  }

  /// بيانات مثال للمعاينة (من المثال المعتمد في المتطلبات).
  String _preview() {
    final sample = CaseFormData(
      occurredAt: DateTime(2026, 9, 25, 19, 30),
      locationText: 'جنوب مركز الرايس',
      caseInfo: '',
      hasInjuries: false,
      extraFields: {for (final f in _fields) f.fieldKey: _sampleValue(f)},
    );
    return CaseTextComposer.composeWith(
      _controller.text,
      sample,
      labels: CaseLabels(
        caseType: _caseTypeLabel ?? 'حالة أمنية',
        reportSource: 'العمليات الموحدة (911)',
        governorate: 'بدر',
        center: 'مركز الرايس',
        parties: const ['الدفاع المدني', 'إدارة الأسلحة والمتفجرات'],
      ),
      fields: _fields,
    );
  }

  static Object? _sampleValue(CaseTypeFieldDef f) => switch (f.inputType) {
    FieldInputType.boolean => true,
    FieldInputType.number => 5,
    FieldInputType.select => f.options.firstOrNull,
    FieldInputType.multiSelect => f.options.take(2).toList(),
    FieldInputType.text || FieldInputType.multiline => f.label,
  };

  @override
  Widget build(BuildContext context) {
    final template = _template;
    final scheme = Theme.of(context).colorScheme;
    if (template == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final errors = TemplateEngine.validate(
      _controller.text,
      CaseTemplateVariables.knownKeys(_fields),
    );
    final dirty = _controller.text.trim() != _savedBody.trim();
    final canRestore =
        ref.read(templateRepositoryProvider).defaultBodyFor(template) != null;

    final variables = [
      for (final f in _fields)
        TemplateVariable(
          CaseTemplateVariables.fieldVariableKey(f),
          'حقل خاص بالنوع',
        ),
      ...CaseTemplateVariables.catalog,
    ];

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('الخروج دون حفظ؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('البقاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('خروج'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('قالب: ${_caseTypeLabel ?? 'عام'}'),
          actions: [
            if (canRestore)
              IconButton(
                tooltip: 'استعادة الافتراضي',
                onPressed: _restoreDefault,
                icon: const Icon(Icons.restore),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: 16,
              style: const TextStyle(fontSize: 15, height: 1.6),
              decoration: const InputDecoration(labelText: 'نص القالب'),
              onChanged: (_) => setState(() {}),
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final e in errors)
                Text(e, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            Text(
              'اضغط لإدراج متغير في مكان المؤشر',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in variables)
                  Tooltip(
                    message: v.description,
                    child: ActionChip(
                      label: Text(v.key),
                      onPressed: () => _insert(v.tag),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('الشروط'),
              children: const [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '{{#اسم}} ... {{/اسم}} يظهر النص إذا كانت القيمة موجودة أو "نعم".\n'
                    '{{^اسم}} ... {{/اسم}} يظهر النص إذا كانت القيمة فارغة أو "لا".',
                    style: TextStyle(height: 1.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'معاينة ببيانات مثال',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _preview(),
                      style: const TextStyle(fontSize: 16, height: 1.7),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: dirty && errors.isEmpty ? _save : null,
              icon: const Icon(Icons.save),
              label: const Text('حفظ القالب'),
            ),
          ),
        ),
      ),
    );
  }
}
