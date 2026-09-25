import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';

/// قائمة منسدلة مرتبطة بقائمة من الإعدادات (محافظة، مركز، مصدر بلاغ...).
class LookupDropdown extends ConsumerWidget {
  const LookupDropdown({
    super.key,
    required this.listKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.parentId,
    this.icon,
    this.allowClear = false,
  });

  final String listKey;
  final String? parentId;
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  final bool allowClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref
            .watch(activeLookupProvider((listKey: listKey, parentId: parentId)))
            .value ??
        const [];
    // قيمة لم تعد مفعلة (عُطلت من الإعدادات) لا تُعرض كخيار جديد لكنها لا تُحذف من الحالة.
    final hasValue = items.any((i) => i.id == value);

    return DropdownButtonFormField<String>(
      key: ValueKey('$listKey|$parentId|$value'),
      initialValue: hasValue ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: allowClear && value != null
            ? IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.close),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item.id, child: Text(item.label)),
      ],
      onChanged: onChanged,
    );
  }
}
