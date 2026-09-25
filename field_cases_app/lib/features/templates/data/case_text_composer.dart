import '../../cases/domain/case_form_data.dart';
import '../../cases/domain/case_type_field.dart';
import '../../settings/data/lookup_repository.dart';
import '../domain/case_template_variables.dart';
import '../domain/template_engine.dart';
import 'template_repository.dart';

/// يصوغ نص الحالة آليًا من القالب المناسب لنوعها.
class CaseTextComposer {
  CaseTextComposer({required this._lookups, required this._templates});

  final LookupRepository _lookups;
  final TemplateRepository _templates;

  Future<String> compose(CaseFormData data) async {
    final template = await _templates.templateFor(data.caseTypeId);
    if (template == null) return '';
    final fields = data.caseTypeId == null
        ? const <CaseTypeFieldDef>[]
        : await _lookups.fieldsForType(data.caseTypeId!);
    return composeWith(
      template.body,
      data,
      labels: await resolveLabels(data),
      fields: fields,
    );
  }

  static String composeWith(
    String templateBody,
    CaseFormData data, {
    required CaseLabels labels,
    List<CaseTypeFieldDef> fields = const [],
  }) {
    return TemplateEngine.render(
      templateBody,
      CaseTemplateVariables.build(data, labels: labels, fields: fields),
    );
  }

  Future<CaseLabels> resolveLabels(CaseFormData data) async {
    Future<String?> label(String? id) async =>
        id == null ? null : (await _lookups.byId(id))?.label;

    final parties = <(int, String)>[];
    for (final id in data.partyIds) {
      final item = await _lookups.byId(id);
      if (item != null) parties.add((item.sortOrder, item.label));
    }
    parties.sort((a, b) => a.$1.compareTo(b.$1));

    return CaseLabels(
      caseType: await label(data.caseTypeId),
      reportSource: await label(data.reportSourceId),
      governorate: await label(data.governorateId),
      center: await label(data.centerId),
      parties: [for (final p in parties) p.$2],
    );
  }
}
