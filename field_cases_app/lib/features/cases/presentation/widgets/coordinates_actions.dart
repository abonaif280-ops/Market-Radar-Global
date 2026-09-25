import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/location/coordinates.dart';

/// نسخ الإحداثية وفتحها في تطبيق الخرائط (تُستخدم في النموذج وفي تفاصيل الحالة).
class CoordinatesActions extends ConsumerWidget {
  const CoordinatesActions({super.key, required this.coordinates, this.label});

  final Coordinates coordinates;
  final String? label;

  static Future<void> copy(
    BuildContext context,
    Coordinates coordinates,
  ) async {
    await Clipboard.setData(ClipboardData(text: coordinates.format()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('نُسخت الإحداثية')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => copy(context, coordinates),
            icon: const Icon(Icons.copy),
            label: const Text('نسخ'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final opened = await ref
                  .read(mapLauncherProvider)
                  .open(coordinates, label: label);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لا يوجد تطبيق خرائط لفتح الإحداثية'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('الخريطة'),
          ),
        ),
      ],
    );
  }
}
