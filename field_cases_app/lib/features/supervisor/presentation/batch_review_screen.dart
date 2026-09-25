import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../cases/domain/case_query.dart';
import '../../cases/presentation/cases_list_screen.dart';

/// حالات دفعة واردة: تحديد، معاينة (بالضغط على الحالة)، اعتماد أو رفض.
class BatchReviewScreen extends ConsumerWidget {
  const BatchReviewScreen({super.key, required this.batchId});

  final String batchId;

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    Set<String> ids,
    VoidCallback clear, {
    required bool approve,
  }) async {
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve ? 'اعتماد ${ids.length} حالة؟' : 'رفض ${ids.length} حالة؟',
        ),
        content: Text(
          approve
              ? 'ستنتقل الحالات إلى السجل المعتمد.'
              : 'ستبقى الحالات محفوظة بحالة "مرفوضة" ولن تُحذف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(approve ? 'اعتماد' : 'رفض'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final inbox = ref.read(inboxRepositoryProvider);
    final count = approve ? await inbox.approve(ids) : await inbox.reject(ids);
    clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'اعتُمدت $count حالة' : 'رُفضت $count حالة'),
      ),
    );
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref) async {
    final ids = await ref.read(inboxRepositoryProvider).pendingCaseIds(batchId);
    if (!context.mounted) return;
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد حالات تنتظر الاعتماد')),
      );
      return;
    }
    await _decide(context, ref, ids.toSet(), () {}, approve: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(inboxBatchesProvider).value ?? const [];
    final batch = batches.where((b) => b.id == batchId).firstOrNull;

    return CasesListScreen(
      title: batch == null ? 'الدفعة' : 'دفعة ${batch.title}',
      selectionMode: true,
      tapOpensDetails: true,
      baseQuery: CaseQuery(sourceBatchId: batchId),
      selectionBarBuilder: (selected, clear) => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () =>
                        _decide(context, ref, selected, clear, approve: false),
              child: Text('رفض (${selected.length})'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: selected.isEmpty
                  ? () => _approveAll(context, ref)
                  : () => _decide(context, ref, selected, clear, approve: true),
              icon: const Icon(Icons.verified),
              label: Text(
                selected.isEmpty
                    ? 'اعتماد الكل (${batch?.pendingCount ?? 0})'
                    : 'اعتماد (${selected.length})',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
