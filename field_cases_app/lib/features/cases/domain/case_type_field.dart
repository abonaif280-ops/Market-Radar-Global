import 'dart:convert';

import 'case_enums.dart';

/// تعريف حقل ديناميكي خاص بنوع حالة (من جدول case_type_fields).
class CaseTypeFieldDef {
  const CaseTypeFieldDef({
    required this.fieldKey,
    required this.label,
    required this.inputType,
    this.options = const [],
    this.isRequired = false,
  });

  factory CaseTypeFieldDef.fromRow({
    required String fieldKey,
    required String label,
    required FieldInputType inputType,
    required String? optionsJson,
    required bool isRequired,
  }) {
    return CaseTypeFieldDef(
      fieldKey: fieldKey,
      label: label,
      inputType: inputType,
      options: optionsJson == null
          ? const []
          : (jsonDecode(optionsJson) as List).cast<String>(),
      isRequired: isRequired,
    );
  }

  final String fieldKey;
  final String label;
  final FieldInputType inputType;
  final List<String> options;
  final bool isRequired;

  /// هل القيمة تعتبر فارغة لغرض التحقق من الحقول الإلزامية.
  bool isEmptyValue(Object? value) {
    return switch (value) {
      null => true,
      final String s => s.trim().isEmpty,
      final List<Object?> l => l.isEmpty,
      // القيمة المنطقية "لا" إجابة صحيحة وليست فراغًا.
      _ => false,
    };
  }
}
