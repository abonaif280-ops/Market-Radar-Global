import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/case_content_hasher.dart';
import '../../domain/case_enums.dart';
import '../../domain/case_form_data.dart';
import '../../domain/case_form_validator.dart';
import '../../domain/case_type_field.dart';
import 'steps/basics_step.dart';
import 'steps/details_step.dart';
import 'steps/review_step.dart';
import 'steps/type_step.dart';

/// النموذج المتدرج لإنشاء حالة جديدة أو تعديل حالة موجودة.
class CaseFormScreen extends ConsumerStatefulWidget {
  const CaseFormScreen({super.key}) : caseId = null, initialData = null;

  const CaseFormScreen.edit({
    super.key,
    required String this.caseId,
    required CaseFormData this.initialData,
  });

  final String? caseId;
  final CaseFormData? initialData;

  bool get isEditing => caseId != null;

  @override
  ConsumerState<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends ConsumerState<CaseFormScreen> {
  static const _steps = CaseFormStep.values;
  static const _titles = {
    CaseFormStep.type: 'نوع الحالة',
    CaseFormStep.basics: 'الأساسيات',
    CaseFormStep.details: 'التفاصيل',
    CaseFormStep.review: 'المراجعة والحفظ',
  };

  late final CaseFormData _data;
  late final String _initialHash;
  late CaseFormStep _step;
  List<CaseTypeFieldDef> _fields = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData?.copy() ?? CaseFormData();
    _initialHash = CaseContentHasher.hash(_data);
    _step = widget.isEditing ? CaseFormStep.basics : CaseFormStep.type;
    if (_data.caseTypeId != null) _loadFields(_data.caseTypeId!);
  }

  Future<void> _loadFields(String caseTypeId) async {
    final fields = await ref.read(caseTypeFieldsProvider(caseTypeId).future);
    if (!mounted || _data.caseTypeId != caseTypeId) return;
    setState(() => _fields = fields);
  }

  bool get _hasChanges => CaseContentHasher.hash(_data) != _initialHash;

  List<CaseValidationError> _errorsFor(CaseStatus target) =>
      CaseFormValidator.validate(_data, targetStatus: target, fields: _fields);

  void _goTo(CaseFormStep step) => setState(() => _step = step);

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == CaseFormStep.type && _data.caseTypeId == null) {
      _showMessage('اختر نوع الحالة أولًا');
      return;
    }
    if (_step.index < _steps.length - 1) _goTo(_steps[_step.index + 1]);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step.index > 0) _goTo(_steps[_step.index - 1]);
  }

  void _onTypeSelected(String caseTypeId) {
    setState(() {
      _data.changeCaseType(caseTypeId);
      _fields = const [];
    });
    _loadFields(caseTypeId);
    _next();
  }

  Future<void> _save(CaseStatus status) async {
    final errors = _errorsFor(status);
    if (errors.isNotEmpty) {
      _showMessage(errors.first.message);
      _goTo(errors.first.step);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(casesRepositoryProvider);
    try {
      final String id;
      if (widget.isEditing) {
        id = widget.caseId!;
        await repo.updateCase(id, _data, status: status);
      } else {
        id = await repo.createCase(_data, status: status);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == CaseStatus.draft ? 'حُفظت الحالة كمسودة' : 'حُفظت الحالة',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('تعذر الحفظ: $e');
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تجاهل التغييرات؟'),
        content: const Text(
          'لم تُحفظ البيانات المدخلة. هل تريد الخروج دون حفظ؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('متابعة الإدخال'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خروج دون حفظ'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == CaseFormStep.review;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_step.index > 0 &&
            !(widget.isEditing && _step == CaseFormStep.basics)) {
          _back();
          return;
        }
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'تعديل الحالة' : 'حالة جديدة'),
          leading: IconButton(
            tooltip: 'إغلاق',
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmDiscard() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: _StepHeader(
              title: _titles[_step]!,
              index: _step.index,
              total: _steps.length,
            ),
          ),
        ),
        body: switch (_step) {
          CaseFormStep.type => TypeStep(
            selectedId: _data.caseTypeId,
            onSelected: _onTypeSelected,
          ),
          CaseFormStep.basics => BasicsStep(
            data: _data,
            onChanged: () => setState(() {}),
          ),
          CaseFormStep.details => DetailsStep(
            data: _data,
            fields: _fields,
            onChanged: () => setState(() {}),
          ),
          CaseFormStep.review => ReviewStep(
            data: _data,
            fields: _fields,
            errors: _errorsFor(CaseStatus.completed),
            onGoToStep: _goTo,
          ),
        },
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: isLast
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _save(CaseStatus.draft),
                          child: const Text('حفظ كمسودة'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _save(CaseStatus.completed),
                          icon: const Icon(Icons.check),
                          label: const Text('حفظ الحالة'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (_step.index > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _back,
                            child: const Text('السابق'),
                          ),
                        ),
                      if (_step.index > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _next,
                          child: const Text('التالي'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.index,
    required this.total,
  });

  final String title;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('الخطوة ${index + 1} من $total'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (index + 1) / total,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
