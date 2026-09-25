import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../cases/domain/case_enums.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgName = ref.watch(orgNameProvider).value;
    final userCode = ref.watch(userCodeProvider).value;
    final role = ref.watch(userRoleProvider).value ?? UserRole.employee;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const _SectionTitle('البيانات الأساسية'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.apartment),
                  title: const Text('اسم الجهة'),
                  subtitle: Text(_orNotSet(orgName)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editSetting(
                    context,
                    ref,
                    key: SettingKeys.orgName,
                    title: 'اسم الجهة',
                    initial: orgName,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('اسم المستخدم أو رمزه'),
                  subtitle: Text(_orNotSet(userCode)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editSetting(
                    context,
                    ref,
                    key: SettingKeys.userCode,
                    title: 'اسم المستخدم أو رمزه',
                    initial: userCode,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('الدور'),
                  subtitle: Text(role == UserRole.supervisor ? 'مشرف' : 'موظف'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('القوائم والقوالب'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('أنواع الحالات، المحافظات، المراكز، المصادر، الجهات'),
              subtitle: Text('قيد التنفيذ — المرحلة 3'),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('الحماية والنسخ الاحتياطي'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('قفل التطبيق، المفاتيح، النسخ الاحتياطي'),
              subtitle: Text('قيد التنفيذ — المرحلتان 13 و14'),
            ),
          ),
        ],
      ),
    );
  }

  static String _orNotSet(String? value) =>
      (value == null || value.isEmpty) ? 'غير محدد' : value;

  Future<void> _editSetting(
    BuildContext context,
    WidgetRef ref, {
    required String key,
    required String title,
    String? initial,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await ref.read(settingsRepositoryProvider).set(key, result.trim());
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
