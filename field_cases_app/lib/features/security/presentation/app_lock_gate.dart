import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'lock_screen.dart';

/// يغطي التطبيق بشاشة القفل عند الفتح وبعد البقاء في الخلفية مدة [timeout].
///
/// يوضع في `MaterialApp.builder` فوق Navigator: ما تحته يبقى كما هو (نموذج
/// لم يُحفظ لا يضيع)، لكنه مخفي وغير قابل للّمس حتى الفتح. كما يُغطّى المحتوى
/// عند الانتقال للخلفية حتى لا تظهر البيانات في معاينة التطبيقات المفتوحة.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 60),
    this.clock = DateTime.now,
  });

  final Widget child;
  final Duration timeout;
  final DateTime Function() clock;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

enum _Status { checking, locked, unlocked }

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  _Status _status = _Status.checking;
  bool _obscured = false;

  /// آخر حالة معروفة للقفل؛ تغطية المحتوى يجب أن تتم فورًا دون انتظار.
  bool _lockOn = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _evaluate() async {
    final enabled = await ref.read(appLockServiceProvider).isEnabled();
    if (!mounted) return;
    setState(() {
      _lockOn = enabled;
      _status = enabled ? _Status.locked : _Status.unlocked;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (_lockOn && _status == _Status.unlocked && !_obscured) {
          setState(() => _obscured = true);
        }
      case AppLifecycleState.paused:
        _backgroundedAt ??= widget.clock();
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        _onResumed(since);
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _onResumed(DateTime? backgroundedAt) async {
    final enabled = await _lockEnabled();
    if (!mounted) return;
    final expired =
        backgroundedAt != null &&
        widget.clock().difference(backgroundedAt) >= widget.timeout;
    setState(() {
      _lockOn = enabled;
      _obscured = false;
      if (enabled && expired) _status = _Status.locked;
    });
  }

  Future<bool> _lockEnabled() => ref.read(appLockServiceProvider).isEnabled();

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockEnabledProvider, (_, next) {
      final on = next.value;
      if (on != null) _lockOn = on;
    });
    final covered = _status != _Status.unlocked || _obscured;
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !covered,
          child: ExcludeSemantics(
            excluding: covered,
            child: IgnorePointer(ignoring: covered, child: widget.child),
          ),
        ),
        if (_status == _Status.locked)
          LockScreen(
            onUnlocked: () => setState(() => _status = _Status.unlocked),
          )
        else if (covered)
          const _PrivacyCover(),
      ],
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: Center(child: Icon(Icons.lock, size: 56, color: scheme.primary)),
    );
  }
}
