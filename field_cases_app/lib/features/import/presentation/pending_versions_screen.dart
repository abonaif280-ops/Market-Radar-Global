import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/duplicate_detector.dart';
import 'version_compare_screen.dart';

/// الحالات التي وصلت لها نسخة أحدث وتنتظر قرار المشرف.
class PendingVersionsScreen extends ConsumerWidget {
  const PendingVersionsScreen({super.key, this.batchId});

  /// null = كل الدفعات.
  final String? batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVersionsProvider(batchId));
    return Scaffold(
      appBar: AppBar(title: const Text('نسخ أحدث تنتظر القرار')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('لا توجد قرارات معلقة'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final v = items[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: const Icon(Icons.difference_outlined, size: 30),
                      title: Text(v.caseTypeLabel),
                      subtitle: Text(
                        '${v.displayCode}\n'
                        'الحالية: إصدار ${v.currentRevision} ← الواردة: إصدار ${v.incomingRevision} • ${v.batchTitle}',
                      ),
                      isThreeLine: true,
                      trailing: Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(DuplicateDetector.label(v.classification)),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => VersionCompareScreen(
                            batchId: v.batchId,
                            caseId: v.caseId,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
