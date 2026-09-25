import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app.dart';
import '../../../app/providers.dart';
import '../../../core/crypto/backup_cipher.dart';
import '../../../core/utils/arabic_format.dart';
import '../../cases/domain/case_enums.dart';
import '../../cases/domain/case_query.dart';
import '../../settings/data/settings_repository.dart';
import '../data/backup_service.dart';

/// اختيار ملف النسخة. مجرد في واجهة لتسهيل الاختبار.
typedef BackupFilePicker = Future<String?> Function();

Future<String?> pickBackupFile() async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  return files.isEmpty ? null : files.first.path;
}

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => pickBackupFile,
);

final lastBackupAtProvider = StreamProvider.autoDispose<DateTime?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.lastBackupAt)
      .map((v) => v == null ? null : DateTime.tryParse(v)?.toLocal()),
);

/// "النسخ الاحتياطي والاستعادة".
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key, this.restorePath});

  /// نسخة فُتحت من تطبيق آخر: تبدأ الاستعادة مباشرة (بعد كلمة المرور والتحذير).
  final String? restorePath;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String? _busyText;

  @override
  void initState() {
    super.initState();
    final path = widget.restorePath;
    if (path != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restore(path);
      });
    }
  }

  Future<T?> _busy<T>(String text, Future<T> Function() run) async {
    setState(() => _busyText = text);
    try {
      return await run();
    } finally {
      if (mounted) setState(() => _busyText = null);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------------------------------------------------ إنشاء

  Future<void> _create() async {
    final isSupervisor =
        ref.read(userRoleProvider).value == UserRole.supervisor;
    final choice = await showDialog<_NewBackupChoice>(
      context: context,
      builder: (_) => _NewPasswordDialog(offerSupervisorKeys: isSupervisor),
    );
    if (choice == null || !mounted) return;
    try {
      final result = await _busy(
        'جارٍ إنشاء النسخة وتشفيرها…',
        () => ref
            .read(backupServiceProvider)
            .create(
              password: choice.password,
              includeSupervisorKeys: choice.includeSupervisorKeys,
            ),
      );
      if (result == null || !mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _BackupResultSheet(result: result),
      );
    } on Exception catch (e) {
      if (mounted) _snack('تعذّر إنشاء النسخة: $e');
    }
  }

  // ------------------------------------------------------------ استعادة

  Future<void> _pickAndRestore() async {
    final path = await ref.read(backupFilePickerProvider)();
    if (path == null || !mounted) return;
    await _restore(path);
  }

  Future<void> _restore(String path) async {
    final service = ref.read(backupServiceProvider);

    StagedRestore? staged;
    String? error;
    while (staged == null) {
      final password = await showDialog<String>(
        context: context,
        builder: (_) => _PasswordDialog(error: error),
      );
      if (password == null || !mounted) return;
      try {
        staged = await _busy(
          'جارٍ فك التشفير وفحص النسخة…',
          () => service.stage(File(path), password),
        );
      } on BackupException catch (e) {
        if (!mounted) return;
        if (!e.wrongPassword) {
          await _showError(e.message);
          return;
        }
        error = e.message;
      }
      if (!mounted) return;
    }

    final current = await ref
        .read(casesRepositoryProvider)
        .countCases(const CaseQuery());
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _RestoreConfirmDialog(staged: staged!, currentCases: current),
    );
    if (confirmed != true || !mounted) {
      await service.discard(staged);
      return;
    }

    final ready = staged;
    try {
      await _busy('جارٍ تجهيز البيانات…', () => service.prepare(ready));
    } on Exception catch (e) {
      await service.discard(ready);
      if (mounted) await _showError('تعذّرت الاستعادة: $e');
      return;
    }
    if (!mounted) return;

    final databaseFile = ref.read(databaseFileProvider);
    final storageRoot = ref.read(attachmentStorageProvider).root;
    final secrets = ref.read(secretStoreProvider);
    // من هنا تُغلق القاعدة ويُعاد بناء التطبيق؛ هذه الشاشة لن تبقى.
    await ref
        .read(appRestartProvider)
        .restart(
          whileClosed: () => BackupService.swap(
            ready,
            databaseFile: databaseFile,
            storageRoot: storageRoot,
            secrets: secrets,
          ),
          afterReopen: (container, error) async {
            final messenger = FieldCasesApp.messengerKey;
            if (error != null) {
              messenger.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    'تعذّرت الاستعادة وبقيت البيانات السابقة كما هي: $error',
                  ),
                ),
              );
              return;
            }
            await BackupService.logRestored(
              container.read(auditLoggerProvider),
              ready.manifest,
              actor: await container
                  .read(settingsRepositoryProvider)
                  .get(SettingKeys.userCode),
            );
            messenger.currentState?.showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 6),
                content: Text(
                  'تمت الاستعادة: ${ready.caseCount} حالة و'
                  '${ready.attachmentCount} صورة',
                ),
              ),
            );
          },
        );
  }

  Future<void> _showError(String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.error_outline, size: 36),
      title: const Text('تعذّرت الاستعادة'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسنًا'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = ref.watch(lastBackupAtProvider).value;
    // يُراقَب ليكون الدور جاهزًا عند فتح حوار الإنشاء.
    ref.watch(userRoleProvider);
    final busy = _busyText != null;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: scheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                last == null
                                    ? 'لم تُنشأ نسخة احتياطية بعد'
                                    : 'آخر نسخة: ${ArabicFormat.dateTime(last)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'النسخة تحتوي كل الحالات والصور والإعدادات، '
                          'مشفرة بكلمة مرور تختارها. لا تُرفع لأي مكان تلقائيًا؛ '
                          'أنت تختار أين تحفظ الملف.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: busy ? null : _create,
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text('إنشاء نسخة احتياطية'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickAndRestore,
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('استعادة نسخة احتياطية'),
                ),
                const SizedBox(height: 20),
                _Hint(
                  icon: Icons.key_off_outlined,
                  text:
                      'إذا نسيت كلمة المرور لا يمكن فتح النسخة، ولا توجد أي '
                      'طريقة لاسترجاعها.',
                ),
                _Hint(
                  icon: Icons.phone_iphone,
                  text:
                      'احفظ الملف خارج الجوال (مثل جهاز الجهة) حتى تستطيع '
                      'الاستعادة إذا فُقد الجوال.',
                ),
              ],
            ),
            if (busy)
              Positioned.fill(
                child: ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_busyText!),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: muted)),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ الحوارات

class _NewBackupChoice {
  const _NewBackupChoice(this.password, this.includeSupervisorKeys);

  final String password;
  final bool includeSupervisorKeys;
}

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog({required this.offerSupervisorKeys});

  final bool offerSupervisorKeys;

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _includeKeys = true;
  bool _acknowledged = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _password.text;
    if (password.length < BackupCipher.minPasswordLength) {
      setState(
        () => _error =
            'كلمة المرور ${BackupCipher.minPasswordLength} أحرف على الأقل',
      );
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    Navigator.of(context).pop(
      _NewBackupChoice(password, widget.offerSupervisorKeys && _includeKeys),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('كلمة مرور النسخة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _password,
              autofocus: true,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                helperText:
                    '${BackupCipher.minPasswordLength} أحرف على الأقل، ويُفضّل عبارة طويلة',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'إظهار' : 'إخفاء',
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.offerSupervisorKeys) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeKeys,
                onChanged: (v) => setState(() => _includeKeys = v ?? false),
                title: const Text('تضمين مفتاح المشرف'),
                subtitle: const Text(
                  'لفتح الحزم المشفرة على جوال جديد دون توزيع مفتاح جديد '
                  'على الموظفين.',
                ),
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: (v) => setState(() => _acknowledged = v ?? false),
              title: const Text(
                'أفهم أنه إذا نسيت كلمة المرور لا يمكن استعادة النسخة',
              ),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: scheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _acknowledged ? _submit : null,
          child: const Text('إنشاء'),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({this.error});

  final String? error;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('كلمة مرور النسخة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              suffixIcon: IconButton(
                tooltip: _obscure ? 'إظهار' : 'إخفاء',
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 12),
            Text(widget.error!, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('فتح النسخة'),
        ),
      ],
    );
  }
}

class _RestoreConfirmDialog extends StatelessWidget {
  const _RestoreConfirmDialog({
    required this.staged,
    required this.currentCases,
  });

  final StagedRestore staged;
  final int currentCases;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = staged.manifest;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, size: 40, color: scheme.error),
      title: const Text('استبدال البيانات الحالية؟'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row('تاريخ النسخة', ArabicFormat.dateTime(m.createdAt.toLocal())),
            if (m.orgName != null) row('الجهة', m.orgName!),
            if (m.userCode != null) row('المستخدم', m.userCode!),
            row('الحالات', '${staged.caseCount}'),
            row('الصور', '${staged.attachmentCount}'),
            if (m.includesSupervisorKeys) row('مفتاح المشرف', 'مضمّن'),
            if (staged.missingFiles > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'تنبيه: ${staged.missingFiles} صورة مسجلة غير موجودة في النسخة.',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ستُحذف كل البيانات الحالية على هذا الجهاز ($currentCases حالة '
                'وصورها) وتحل محلها بيانات النسخة. لا يمكن التراجع. '
                'يُنصح بإنشاء نسخة احتياطية للبيانات الحالية أولًا.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
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
          child: const Text('استبدال البيانات'),
        ),
      ],
    );
  }
}

class _BackupResultSheet extends ConsumerWidget {
  const _BackupResultSheet({required this.result});

  final BackupResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final m = result.manifest;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.verified_user, size: 48, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              'النسخة جاهزة ومشفرة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${m.caseCount} حالة • ${m.attachmentCount} صورة'
              '${m.includesSupervisorKeys ? ' • مع مفتاح المشرف' : ''}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              result.file.uri.pathSegments.last,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(shareServiceProvider).shareFile(result.file.path),
              icon: const Icon(Icons.save_alt),
              label: const Text('حفظ الملف أو مشاركته'),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر "حفظ في الملفات" أو انقله لجهاز الجهة. لا ترسل كلمة المرور '
              'مع الملف.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
