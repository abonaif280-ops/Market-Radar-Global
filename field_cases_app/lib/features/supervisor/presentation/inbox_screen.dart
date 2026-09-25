import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/arabic_format.dart';
import '../data/inbox_repository.dart';
import 'batch_review_screen.dart';

/// "الدفعات الواردة": بطاقة لكل حزمة مستوردة (الجهة، العدد، الصور، التاريخ).
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(inboxBatchesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الدفعات الواردة')),
      body: batches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const _Empty()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _BatchCard(batch: items[i]),
              ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final InboxBatch batch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = batch.pendingCount == 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BatchReviewScreen(batchId: batch.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: done
                    ? scheme.surfaceContainerHighest
                    : scheme.primaryContainer,
                child: Icon(
                  done ? Icons.inventory_2_outlined : Icons.move_to_inbox,
                  color: done ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${batch.caseCount} حالة • ${batch.imageCount} صورة'),
                    Text(
                      ArabicFormat.dateTime(batch.importedAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!done)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.tertiaryContainer,
                      side: BorderSide.none,
                      label: Text('${batch.pendingCount} للمراجعة'),
                    )
                  else
                    Text(
                      'مكتملة',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  if (batch.approvedCount > 0)
                    Text(
                      '${batch.approvedCount} معتمدة',
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: scheme.outline),
          const SizedBox(height: 12),
          const Text('لا توجد دفعات واردة'),
          const SizedBox(height: 4),
          Text(
            'استورد حزمة من "استيراد بيانات"',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
