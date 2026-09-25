import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/security/pin_attempt_guard.dart';
import '../../../core/security/pin_hasher.dart';
import '../../../shared/widgets/pin_dialog.dart';

final _biometricStateProvider =
    FutureProvider.autoDispose<({bool available, bool enabled})>((ref) async {
      ref.watch(appLockEnabledProvider);
      final service = ref.watch(appLockServiceProvider);
      return (
        available: await service.biometricAvailable(),
        enabled: await service.biometricEnabled(),
      );
    });

/// تفعيل/إيقاف قفل التطبيق، البصمة، وتغيير رمز القفل.
class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  static const _newPinMessage =
      'اختر رمزًا من ${PinHasher.pinLength} أرقام لفتح التطبيق. '
      'يختلف عن رمز المشرف.';

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final pin = await PinDialog.createNew(
      context,
      title: 'رمز قفل التطبيق',
      message: _newPinMessage,
    );
    if (pin == null) return;
    final service = ref.read(appLockServiceProvider);
    final canBio = await service.biometricAvailable();
    await service.enable(pin, useBiometric: canBio);
    ref.invalidate(_biometricStateProvider);
    if (!context.mounted) return;
    _snack(context, 'فُعّل قفل التطبيق');
  }

  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    final pin = await PinDialog.show(
      context,
      title: 'إيقاف قفل التطبيق',
      message: 'أدخل رمز القفل الحالي.',
    );
    if (pin == null) return;
    final result = await ref.read(appLockServiceProvider).disable(pin);
    if (context.mounted) _report(context, result, 'أُوقف قفل التطبيق');
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final current = await PinDialog.show(context, title: 'رمز القفل الحالي');
    if (current == null || !context.mounted) return;
    final next = await PinDialog.createNew(
      context,
      title: 'رمز القفل الجديد',
      message: _newPinMessage,
    );
    if (next == null) return;
    final result = await ref
        .read(appLockServiceProvider)
        .changePin(current, next);
    if (context.mounted) _report(context, result, 'غُيّر رمز القفل');
  }

  void _report(BuildContext context, PinCheck result, String success) {
    _snack(context, switch (result) {
      PinAccepted() => success,
      PinRejected(:final remainingAttempts) =>
        'رمز خاطئ — المحاولات المتبقية: $remainingAttempts',
      PinLockedOut(:final retryAfter) =>
        'محاولات كثيرة. حاول بعد ${retryAfter.inSeconds} ثانية',
    });
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(appLockEnabledProvider).value ?? false;
    final bio = ref.watch(_biometricStateProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('قفل التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('قفل التطبيق'),
                  subtitle: const Text(
                    'يُطلب الفتح عند التشغيل وبعد دقيقة في الخلفية',
                  ),
                  value: enabled,
                  onChanged: (v) =>
                      v ? _enable(context, ref) : _disable(context, ref),
                ),
                if (enabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('الفتح بالبصمة أو الوجه'),
                    subtitle: Text(
                      bio?.available == false
                          ? 'غير متاح على هذا الجهاز'
                          : 'رمز القفل يبقى بديلًا دائمًا',
                    ),
                    value: bio?.enabled == true && bio?.available == true,
                    onChanged: bio?.available == true
                        ? (v) async {
                            await ref
                                .read(appLockServiceProvider)
                                .setBiometric(v);
                            ref.invalidate(_biometricStateProvider);
                          }
                        : null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('تغيير رمز القفل'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _changePin(context, ref),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'يُخزَّن رمز القفل كتجزئة Argon2id في Keychain/Keystore ولا يُحفظ '
            'الرمز نفسه. بعد 5 محاولات خاطئة يتوقف الإدخال 30 ثانية. '
            'قاعدة البيانات مشفرة على الجهاز بمفتاح منفصل.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
