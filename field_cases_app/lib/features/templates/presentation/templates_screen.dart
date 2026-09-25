import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/seed_data.dart';
import 'template_editor_screen.dart';

/// قائمة قوالب الصياغة: قالب لكل نوع حالة + القالب العام.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  Future<void> _addForType(BuildContext context, WidgetRef ref) async {
    final existing = (ref.read(templatesListProvider).value ?? const [])
        .map((t) => t.template.caseTypeId)
        .toSet();
    final types = await ref
        .read(lookupRepositoryProvider)
        .activeItems(LookupKeys.caseType);
    final available = types.where((t) => !existing.contains(t.id)).toList();
    if (!context.mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كل أنواع الحالات لها قوالب')),
      );
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('قالب خاص لنوع الحالة:'),
            ),
            for (final type in available)
              ListTile(
                title: Text(type.label),
                onTap: () => Navigator.of(context).pop(type.id),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    final label = available.firstWhere((t) => t.id == chosen).label;
    final id = await ref
        .read(templateRepositoryProvider)
        .createForCaseType(chosen, label);
    if (!context.mounted) return;
    await TemplateEditorScreen.open(context, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('قوالب الصياغة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addForType(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('قالب لنوع'),
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'يصوغ التطبيق نص الحالة من قالب نوعها. الأنواع التي ليس لها '
                  'قالب خاص تستخدم القالب العام.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            final item = items[index - 1];
            return Card(
              child: ListTile(
                leading: Icon(
                  item.caseTypeLabel == null
                      ? Icons.article_outlined
                      : Icons.text_snippet_outlined,
                ),
                title: Text(item.caseTypeLabel ?? 'القالب العام'),
                subtitle: Text(
                  item.template.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () =>
                    TemplateEditorScreen.open(context, item.template.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
