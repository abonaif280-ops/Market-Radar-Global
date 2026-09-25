import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/case_enums.dart';
import '../../domain/case_type_field.dart';

/// يرسم حقل إدخال بحسب نوعه المعرّف في case_type_fields.
class DynamicFieldInput extends StatelessWidget {
  const DynamicFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final CaseTypeFieldDef field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  String get _label => field.isRequired ? '${field.label} *' : field.label;

  @override
  Widget build(BuildContext context) {
    switch (field.inputType) {
      case FieldInputType.boolean:
        final current = value == true;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_label),
          subtitle: Text(current ? 'نعم' : 'لا'),
          value: current,
          onChanged: onChanged,
        );

      case FieldInputType.select:
        return DropdownButtonFormField<String>(
          initialValue: field.options.contains(value) ? value as String : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: _label),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        );

      case FieldInputType.multiSelect:
        final selected = (value as List?)?.cast<String>() ?? const <String>[];
        return InputDecorator(
          decoration: InputDecoration(labelText: _label),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in field.options)
                FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (on) {
                    final next = [...selected];
                    on ? next.add(option) : next.remove(option);
                    onChanged(next);
                  },
                ),
            ],
          ),
        );

      case FieldInputType.number:
        return TextFormField(
          initialValue: value?.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: _label),
          onChanged: (text) => onChanged(int.tryParse(text)),
        );

      case FieldInputType.text:
      case FieldInputType.multiline:
        final multiline = field.inputType == FieldInputType.multiline;
        return TextFormField(
          initialValue: value as String?,
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? 6 : 1,
          decoration: InputDecoration(labelText: _label),
          onChanged: onChanged,
        );
    }
  }
}
