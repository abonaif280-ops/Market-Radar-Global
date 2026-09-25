import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/widgets/pin_dialog.dart';
import '../../cases/domain/case_enums.dart';
import '../data/role_service.dart';

/// التحويل بين وضعي الموظف والمشرف، وعرض بصمة مفتاح المشرف.
class SupervisorModeScreen extends ConsumerStatefulWidget {
  const SupervisorModeScreen({super.key});

  @override
  ConsumerState<SupervisorModeScreen> createState() =>
      _SupervisorModeScreenState();
}

class _SupervisorModeScreenState extends ConsumerState<SupervisorModeScreen> {
  bool _busy = false;

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<T?> _withBusy<T>(Future<T> Function() action) async {
    setState(() => _busy = true);
    try {
      return await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _becomeSupervisor() async {
    final roles = ref.read(roleServiceProvider);
    if (!await roles.hasSupervisorPin()) {
      if (!mounted) return;
      final pin = await PinDialog.createNew(context);
      if (pin == null) return;
      await _withBusy(() => roles.setupSupervisor(pin));
      ref.invalidate(supervisorPublicKeyProvider);
      _show('تم تفعيل وضع المشرف');
      return;
    }

    String? error;
    while (true) {
      if (!mounted) return;
      final pin = await PinDialog.show(
        context,
        title: 'رمز المشرف',
        error: error,
      );
      if (pin == null) return;
      final result = await _withBusy(() => roles.switchToSupervisor(pin));
      switch (result) {
        case RoleChanged():
          _show('تم التحويل إلى وضع المشرف');
          return;
        case WrongPin(:final remainingAttempts):
          error = 'رمز غير صحيح. المحاولات المتبقية: $remainingAttempts';
        case LockedOut(:final retryAfter):
          _show('محاولات كثيرة. انتظر ${retryAfter.inSeconds} ثانية.');
          return;
        case null:
          return;
      }
    }
  }

  Future<void> _becomeEmployee() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('العودة لوضع الموظف؟'),
        content: const Text(
          'ستختفي شاشات الاستيراد والدفعات الواردة. لن تُحذف أي بيانات، '
          'ويمكن العودة لوضع المشرف بالرمز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('العودة لوضع الموظف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(roleServiceProvider).switchToEmployee();
  }

  Future<void> _changePin() async {
    final current = await PinDialog.show(context, title: 'الرمز الحالي');
    if (current == null || !mounted) return;
    final next = await PinDialog.createNew(context);
    if (next == null) return;
    final result = await _withBusy(
      () => ref.read(roleServiceProvider).changePin(current, next),
    );
    switch (result) {
      case RoleChanged():
        _show('تم تغيير الرمز');
      case WrongPin():
        _show('الرمز الحالي غير صحيح');
      case LockedOut(:final retryAfter):
        _show('محاولات كثيرة. انتظر ${retryAfter.inSeconds} ثانية.');
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider).value ?? UserRole.employee;
    final isSupervisor = role == UserRole.supervisor;
    final publicKey = ref.watch(supervisorPublicKeyProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('وضع المشرف')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) const LinearProgressIndicator(),
            Card(
              color: isSupervisor ? scheme.primaryContainer : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      isSupervisor ? Icons.verified_user : Icons.person,
                      size: 56,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSupervisor
                          ? 'الوضع الحالي: مشرف'
                          : 'الوضع الحالي: موظف',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSupervisor
                          ? 'يمكنك استيراد حزم الموظفين ومراجعة الحالات الواردة واعتمادها.'
                          : 'وضع المشرف يضيف: استيراد الحزم، الدفعات الواردة، المراجعة والاعتماد.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isSupervisor)
              FilledButton.icon(
                onPressed: _becomeSupervisor,
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('التحويل إلى وضع المشرف'),
              )
            else ...[
              if (publicKey != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('بصمة مفتاح المشرف'),
                    subtitle: SelectableText(
                      publicKey.fingerprint,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                child: Text(
                  'سيستلم الموظفون مفتاحك العام حضوريًا (رمز QR) لتشفير حزمهم '
                  'بحيث لا يفتحها غير جهازك، ويطابقون هذه البصمة معك.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _changePin,
                icon: const Icon(Icons.password),
                label: const Text('تغيير رمز المشرف'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _becomeEmployee,
                icon: const Icon(Icons.person_outline),
                label: const Text('العودة لوضع الموظف'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
