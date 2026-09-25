import 'package:flutter/material.dart';

import '../../domain/case_enums.dart';

/// شارة حالة السجل بلون يميزها.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final DisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (status) {
      DisplayStatus.draft => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.edit_note,
      ),
      DisplayStatus.completed || DisplayStatus.ready => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.task_alt,
      ),
      DisplayStatus.exported || DisplayStatus.approved => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.check_circle,
      ),
      DisplayStatus.modifiedAfterExport => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.change_circle_outlined,
      ),
      DisplayStatus.imported || DisplayStatus.underReview => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.inbox,
      ),
      DisplayStatus.rejected => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.block,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
