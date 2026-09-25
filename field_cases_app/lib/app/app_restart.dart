import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';

/// بعد إعادة الفتح: [error] غير null إذا فشلت العملية وأُعيدت البيانات السابقة.
typedef AfterReopen = Future<void> Function(
  ProviderContainer container,
  Object? error,
);

/// يسمح لعملية (مثل الاستعادة) بإغلاق القاعدة واستبدال ملفاتها ثم إعادة بناء
/// التطبيق كاملًا بحاوية Riverpod جديدة — بدون أن يغلق المستخدم التطبيق.
class AppRestartController {
  _AppRootState? _root;

  bool get isAttached => _root != null;

  Future<void> restart({
    required Future<void> Function() whileClosed,
    AfterReopen? afterReopen,
  }) {
    final root = _root;
    if (root == null) {
      throw StateError('AppRestartController is not attached to AppRoot');
    }
    return root._restart(whileClosed, afterReopen);
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.controller,
    required this.initial,
    required this.bootstrap,
    this.app = const FieldCasesApp(),
  });

  final AppRestartController controller;
  final ProviderContainer initial;

  /// ينشئ حاوية جديدة (يفتح القاعدة ويجهز الخدمات).
  final Future<ProviderContainer> Function() bootstrap;

  /// واجهة التطبيق (تُستبدل في الاختبارات).
  final Widget app;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late ProviderContainer _container = widget.initial;
  int _generation = 0;
  bool _restarting = false;
  bool _fatal = false;

  @override
  void initState() {
    super.initState();
    widget.controller._root = this;
  }

  @override
  void dispose() {
    if (widget.controller._root == this) widget.controller._root = null;
    super.dispose();
  }

  Future<void> _restart(
    Future<void> Function() whileClosed,
    AfterReopen? afterReopen,
  ) async {
    // فصل الواجهة عن القاعدة قبل إغلاقها.
    setState(() => _restarting = true);
    await WidgetsBinding.instance.endOfFrame;
    final old = _container;
    await old.read(appDatabaseProvider).close();
    // لا يبقى أي مستمع قديم قد يعيد فتح القاعدة أثناء استبدال ملفاتها.
    old.dispose();
    Object? error;
    try {
      await whileClosed();
    } catch (e) {
      error = e;
    }
    final ProviderContainer fresh;
    try {
      fresh = await widget.bootstrap();
    } catch (e) {
      if (mounted) setState(() => _fatal = true);
      rethrow;
    }
    if (!mounted) return;
    setState(() {
      _container = fresh;
      _generation++;
      _restarting = false;
    });
    await afterReopen?.call(fresh, error);
  }

  @override
  Widget build(BuildContext context) {
    if (_fatal) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'تعذّر فتح البيانات. أغلق التطبيق وافتحه من جديد.',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      );
    }
    if (_restarting) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return UncontrolledProviderScope(
      key: ValueKey(_generation),
      container: _container,
      child: widget.app,
    );
  }
}
