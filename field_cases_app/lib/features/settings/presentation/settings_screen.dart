import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../cases/domain/case_enums.dart';
import '../../../core/db/seed_data.dart';
import '../data/settings_repository.dart';
import '../../templates/presentation/templates_screen.dart';
import '../../supervisor/presentation/supervisor_mode_screen.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../security/presentation/app_lock_settings_screen.dart';
import '../../security/presentation/recipient_key_screen.dart';
import 'lookup_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgName = ref.watch(orgNameProvider).value;
    final userCode = ref.watch(userCodeProvider).value;
    final orgCode = ref.watch(orgCodeProvider).value;
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
                  leading: const Icon(Icons.tag),
                  title: const Text('رمز الجهة'),
                  subtitle: Text(_orNotSet(orgCode)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editSetting(
                    context,
                    ref,
                    key: SettingKeys.orgCode,
                    title: 'رمز الجهة',
                    initial: orgCode,
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
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupervisorModeScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('القوائم'),
          Card(
            child: Column(
              children: [
                for (final (i, list) in _lists.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: Icon(list.icon),
                    title: Text(list.title),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LookupListScreen(
                          listKey: list.key,
                          title: list.title,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('قوالب صياغة الحالات'),
              subtitle: const Text('نص الحالة المولد تلقائيًا لكل نوع'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TemplatesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('الحماية والنسخ الاحتياطي'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('مفتاح التشفير (مفتاح المشرف)'),
                  subtitle: Text(
                    ref.watch(recipientKeyProvider).value == null
                        ? 'غير مضبوط — الحزم غير مشفرة'
                        : 'مضبوط — الحزم تُشفَّر للمشرف',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecipientKeyScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('قفل التطبيق'),
                  subtitle: Text(
                    ref.watch(appLockEnabledProvider).value == true
                        ? 'مفعّل'
                        : 'غير مفعّل',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AppLockSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('النسخ الاحتياطي والاستعادة'),
                  subtitle: const Text('نسخة مشفرة بكلمة مرور تحفظها بنفسك'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BackupScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _lists = [
    (
      key: LookupKeys.caseType,
      title: 'أنواع الحالات',
      icon: Icons.category_outlined,
    ),
    (
      key: LookupKeys.governorate,
      title: 'المحافظات',
      icon: Icons.location_city,
    ),
    (key: LookupKeys.center, title: 'المراكز', icon: Icons.apartment),
    (
      key: LookupKeys.reportSource,
      title: 'مصادر البلاغ',
      icon: Icons.call_received,
    ),
    (
      key: LookupKeys.party,
      title: 'الجهات المباشرة',
      icon: Icons.groups_outlined,
    ),
  ];

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
