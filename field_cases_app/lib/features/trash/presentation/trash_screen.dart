import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/arabic_format.dart';
import '../data/trash_repository.dart';

/// "المحذوفات": استعادة حالة أو حذفها نهائيًا.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever, size: 40, color: scheme.error),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _purge(
    BuildContext context,
    WidgetRef ref,
    DeletedCase item,
  ) async {
    final ok = await _confirm(
      context,
      title: 'حذف نهائي؟',
      message:
          'ستُحذف الحالة ${item.displayCode} وصورها (${item.photoCount}) من '
          'الجهاز نهائيًا. لا يمكن التراجع.',
      action: 'حذف نهائي',
    );
    if (!ok) return;
    await ref.read(trashRepositoryProvider).purge(item.id);
    if (context.mounted) _snack(context, 'حُذفت الحالة نهائيًا');
  }

  Future<void> _purgeAll(BuildContext context, WidgetRef ref, int count) async {
    final ok = await _confirm(
      context,
      title: 'إفراغ المحذوفات؟',
      message:
          'ستُحذف $count حالة وصورها، وصور محذوفة سابقًا من الحالات، نهائيًا. '
          'لا يمكن التراجع.',
      action: 'إفراغ',
    );
    if (!ok) return;
    final result = await ref.read(trashRepositoryProvider).purgeAll();
    if (context.mounted) {
      _snack(context, 'حُذفت ${result.cases} حالة و${result.files} ملف');
    }
  }

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(deletedCasesProvider);
    final scheme = Theme.of(context).colorScheme;
    final list = items.value ?? const <DeletedCase>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحذوفات'),
        actions: [
          if (list.isNotEmpty)
            TextButton(
              onPressed: () => _purgeAll(context, ref, list.length),
              child: Text('إفراغ', style: TextStyle(color: scheme.error)),
            ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 56,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    const Text('لا توجد حالات محذوفة'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Text(
                      'الحالات المحذوفة لا تظهر في القوائم ولا البحث ولا '
                      'التصدير، ويمكن استعادتها كاملة بصورها.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    );
                  }
                  final item = items[i - 1];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.caseTypeLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.displayCode} • ${item.photoCount} صورة',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            'حُذفت ${ArabicFormat.dateTime(item.deletedAt)}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () => _purge(context, ref, item),
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: scheme.error,
                                ),
                                label: Text(
                                  'حذف نهائي',
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                onPressed: () async {
                                  await ref
                                      .read(trashRepositoryProvider)
                                      .restore(item.id);
                                  if (context.mounted) {
                                    _snack(context, 'استُعيدت الحالة');
                                  }
                                },
                                icon: const Icon(Icons.restore),
                                label: const Text('استعادة'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
