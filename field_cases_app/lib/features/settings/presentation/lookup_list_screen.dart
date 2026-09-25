import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/seed_data.dart';

/// إدارة قائمة قابلة للتعديل: إضافة، إعادة تسمية، تفعيل/تعطيل.
///
/// لا يوجد حذف نهائي حتى لا تفقد الحالات القديمة ارتباطها بالعنصر.
class LookupListScreen extends ConsumerWidget {
  const LookupListScreen({
    super.key,
    required this.listKey,
    required this.title,
  });

  final String listKey;
  final String title;

  bool get _needsParent => listKey == LookupKeys.center;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String label, String? parentId})>(
      context: context,
      builder: (_) =>
          _ItemDialog(title: 'إضافة إلى "$title"', needsParent: _needsParent),
    );
    if (result == null) return;
    await ref
        .read(lookupRepositoryProvider)
        .add(listKey: listKey, label: result.label, parentId: result.parentId);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    LookupItem item,
  ) async {
    final result = await showDialog<({String label, String? parentId})>(
      context: context,
      builder: (_) => _ItemDialog(
        title: 'تعديل الاسم',
        initialLabel: item.label,
        needsParent: false,
      ),
    );
    if (result == null) return;
    await ref.read(lookupRepositoryProvider).rename(item.id, result.label);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(allLookupProvider(listKey));
    final governorates = _needsParent
        ? {
            for (final g
                in ref.watch(allLookupProvider(LookupKeys.governorate)).value ??
                    const <LookupItem>[])
              g.id: g.label,
          }
        : const <String, String>{};

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('القائمة فارغة'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        item.label,
                        style: item.isActive
                            ? null
                            : TextStyle(
                                color: Theme.of(context).disabledColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                      ),
                      subtitle: item.parentId == null
                          ? null
                          : Text(governorates[item.parentId] ?? ''),
                      onTap: () => _rename(context, ref, item),
                      trailing: Switch(
                        value: item.isActive,
                        onChanged: (on) => ref
                            .read(lookupRepositoryProvider)
                            .setActive(item.id, active: on),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ItemDialog extends ConsumerStatefulWidget {
  const _ItemDialog({
    required this.title,
    required this.needsParent,
    this.initialLabel,
  });

  final String title;
  final bool needsParent;
  final String? initialLabel;

  @override
  ConsumerState<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends ConsumerState<_ItemDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialLabel,
  );
  String? _parentId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid =>
      _controller.text.trim().isNotEmpty &&
      (!widget.needsParent || _parentId != null);

  @override
  Widget build(BuildContext context) {
    final governorates = widget.needsParent
        ? ref
                  .watch(
                    activeLookupProvider((
                      listKey: LookupKeys.governorate,
                      parentId: null,
                    )),
                  )
                  .value ??
              const <LookupItem>[]
        : const <LookupItem>[];

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.needsParent) ...[
            DropdownButtonFormField<String>(
              initialValue: _parentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'المحافظة'),
              items: [
                for (final g in governorates)
                  DropdownMenuItem(value: g.id, child: Text(g.label)),
              ],
              onChanged: (id) => setState(() => _parentId = id),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'الاسم'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _valid
              ? () => Navigator.of(context)
                    .pop((label: _controller.text.trim(), parentId: _parentId))
              : null,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
