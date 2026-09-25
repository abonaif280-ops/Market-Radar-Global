import 'package:field_cases/features/security/data/app_lock_service.dart';

/// قفل التطبيق معطل في اختبارات الواجهة (لا قاعدة بيانات حقيقية).
class DisabledAppLock implements AppLockService {
  @override
  Future<bool> isEnabled() async => false;

  @override
  Stream<bool> watchEnabled() => Stream.value(false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
