import 'package:flutter/material.dart';

/// الحالات السابقة — تُستكمل القائمة والفلاتر والتحميل التدريجي في المرحلة 6.
class CasesListScreen extends StatelessWidget {
  const CasesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الحالات السابقة')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 72, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              'لا توجد حالات بعد',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'ابدأ بزر "حالة جديدة"',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
