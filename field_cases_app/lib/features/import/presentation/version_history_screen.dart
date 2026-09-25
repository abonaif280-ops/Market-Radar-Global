import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/arabic_format.dart';
import '../../packages/domain/case_diff.dart';
import '../data/version_resolution_service.dart';

/// سجل إصدارات الحالة: النسخ السابقة أو الواردة المحفوظة.
class VersionHistoryScreen extends ConsumerWidget {
  const VersionHistoryScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(caseVersionsProvider(caseId));
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الإصدارات')),
      body: versions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('لا توجد إصدارات محفوظة'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final v = items[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${v.revision}')),
                      title: Text(v.sourceLabel),
                      subtitle: Text(
                        'الإصدار ${v.revision} • حُفظ ${ArabicFormat.dateTime(v.createdAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _VersionDetails(entry: v),
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

class _VersionDetails extends StatelessWidget {
  const _VersionDetails({required this.entry});

  final CaseVersionEntry entry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // المقارنة بنفسها تعطي كل الحقول بقيمها بنفس التنسيق المستخدم في المقارنة.
    final fields = CaseDiff.fields(
      entry.snapshot,
      entry.snapshot,
    ).where((f) => f.current != '—').toList();
    return Scaffold(
      appBar: AppBar(title: Text('الإصدار ${entry.revision}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(entry.sourceLabel, style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in fields)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.label,
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            f.current,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'الصور: ${entry.snapshot.attachments.length}',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
