import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';
import '../../../../../core/db/seed_data.dart';

/// الخطوة 1: اختيار نوع الحالة من أزرار كبيرة.
class TypeStep extends ConsumerWidget {
  const TypeStep({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;

  static const Map<String, IconData> _icons = {
    'SOLID_OBJECT': Icons.hexagon_outlined,
    'SHRAPNEL': Icons.scatter_plot_outlined,
    'DRONE': Icons.flight,
    'FIRE': Icons.local_fire_department_outlined,
    'SECURITY_CASE': Icons.shield_outlined,
    'SECURITY_INCIDENT': Icons.report_outlined,
    'OTHER': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types =
        ref
            .watch(
              activeLookupProvider((
                listKey: LookupKeys.caseType,
                parentId: null,
              )),
            )
            .value ??
        const [];
    final scheme = Theme.of(context).colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final selected = type.id == selectedId;
        return Card(
          color: selected ? scheme.primaryContainer : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(type.id),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icons[type.code] ?? Icons.label_outline,
                  size: 36,
                  color: selected ? scheme.onPrimaryContainer : scheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  type.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
