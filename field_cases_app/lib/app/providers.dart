import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/db/audit_logger.dart';
import '../features/cases/data/cases_repository.dart';
import '../features/cases/domain/case_enums.dart';
import '../features/settings/data/lookup_repository.dart';
import '../features/settings/data/settings_repository.dart';

/// تُستبدل في main() بالقاعدة الفعلية، وفي الاختبارات بقاعدة في الذاكرة.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

final lookupRepositoryProvider = Provider<LookupRepository>(
  (ref) => LookupRepository(ref.watch(appDatabaseProvider)),
);

final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => CasesRepository(ref.watch(appDatabaseProvider)),
);

final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => AuditLogger(ref.watch(appDatabaseProvider)),
);

final userRoleProvider = StreamProvider<UserRole>(
  (ref) => ref.watch(settingsRepositoryProvider).watchRole(),
);

final orgNameProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(SettingKeys.orgName),
);

final userCodeProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(SettingKeys.userCode),
);

final todayCasesCountProvider = StreamProvider<int>(
  (ref) => ref.watch(casesRepositoryProvider).watchTodayCount(),
);
