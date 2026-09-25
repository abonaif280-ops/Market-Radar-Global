import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/security/pin_attempt_guard.dart';
import '../../../core/security/pin_hasher.dart';

/// شاشة القفل: بصمة تلقائيًا إن كانت مفعلة، ثم لوحة أرقام لرمز PIN.
///
/// لوحة أرقام مخصصة (بدون حقل نص) لأنها تُعرض فوق Navigator التطبيق.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _biometric = false;
  DateTime? _lockedUntil;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometric());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    final service = ref.read(appLockServiceProvider);
    final enabled = await service.biometricEnabled();
    if (!mounted) return;
    setState(() => _biometric = enabled);
    if (enabled) await _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    if (_busy) return;
    final ok = await ref.read(appLockServiceProvider).unlockWithBiometric();
    if (ok && mounted) widget.onUnlocked();
  }

  bool get _lockedOut =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  void _press(String digit) {
    if (_busy || _lockedOut || _pin.length >= PinHasher.pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == PinHasher.pinLength) _submit();
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref.read(appLockServiceProvider).verifyPin(_pin);
    if (!mounted) return;
    switch (result) {
      case PinAccepted():
        widget.onUnlocked();
        return;
      case PinRejected(:final remainingAttempts):
        _error = 'رمز خاطئ — المحاولات المتبقية: $remainingAttempts';
      case PinLockedOut(:final retryAfter):
        _startLockout(retryAfter);
    }
    setState(() {
      _pin = '';
      _busy = false;
    });
  }

  void _startLockout(Duration retryAfter) {
    _lockedUntil = DateTime.now().add(retryAfter);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!_lockedOut) {
        t.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() => _error = _lockoutMessage());
      }
    });
    _error = _lockoutMessage();
  }

  String _lockoutMessage() {
    final seconds = _lockedUntil!.difference(DateTime.now()).inSeconds + 1;
    return 'محاولات كثيرة. حاول بعد $seconds ثانية';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = _busy || _lockedOut;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  Icon(Icons.lock, size: 56, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'التطبيق مقفل',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أدخل رمز القفل',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _Dots(filled: _pin.length),
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        _error ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: _Keypad(
                      enabled: !disabled,
                      onDigit: _press,
                      onBackspace: _backspace,
                      onBiometric: _biometric ? _tryBiometric : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 0; i < PinHasher.pinLength; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? scheme.primary : Colors.transparent,
              border: Border.all(color: scheme.primary, width: 2),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    Widget key(String d) => _KeyButton(
      onPressed: enabled ? () => onDigit(d) : null,
      child: Text(d, style: const TextStyle(fontSize: 28)),
    );
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            onBiometric == null
                ? const SizedBox(width: 76, height: 76)
                : _KeyButton(
                    tooltip: 'فتح بالبصمة',
                    onPressed: enabled ? onBiometric : null,
                    child: const Icon(Icons.fingerprint, size: 34),
                  ),
            key('0'),
            _KeyButton(
              tooltip: 'حذف',
              onPressed: enabled ? onBackspace : null,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.onPressed,
    required this.child,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 76,
        height: 76,
        child: TextButton(
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
    return tooltip == null
        ? button
        : Semantics(label: tooltip, button: true, child: button);
  }
}
