import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/db/audit_logger.dart';
import '../features/cases/data/cases_repository.dart';
import '../features/cases/domain/case_enums.dart';
import '../features/cases/domain/case_type_field.dart';
import '../features/cases/domain/case_views.dart';
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

final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => AuditLogger(ref.watch(appDatabaseProvider)),
);

final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => CasesRepository(
    ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    audit: ref.watch(auditLoggerProvider),
  ),
);

final userRoleProvider = StreamProvider<UserRole>(
  (ref) => ref.watch(settingsRepositoryProvider).watchRole(),
);

final orgNameProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(SettingKeys.orgName),
);

final orgCodeProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(SettingKeys.orgCode),
);

final userCodeProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(SettingKeys.userCode),
);

final todayCasesCountProvider = StreamProvider<int>(
  (ref) => ref.watch(casesRepositoryProvider).watchTodayCount(),
);

final recentCasesProvider = StreamProvider<List<CaseListItem>>(
  (ref) => ref.watch(casesRepositoryProvider).watchRecent(),
);

final caseDetailsProvider = StreamProvider.family<CaseDetails?, String>(
  (ref, id) => ref.watch(casesRepositoryProvider).watchDetails(id),
);

/// عناصر قائمة مفعلة، مع تصفية اختيارية بالعنصر الأب (المراكز حسب المحافظة).
final activeLookupProvider =
    StreamProvider.family<
      List<LookupItem>,
      ({String listKey, String? parentId})
    >(
      (ref, args) => ref
          .watch(lookupRepositoryProvider)
          .watchActiveItems(args.listKey, parentId: args.parentId),
    );

final allLookupProvider = StreamProvider.family<List<LookupItem>, String>(
  (ref, listKey) => ref.watch(lookupRepositoryProvider).watchAllItems(listKey),
);

final caseTypeFieldsProvider =
    FutureProvider.family<List<CaseTypeFieldDef>, String>(
      (ref, caseTypeId) =>
          ref.watch(lookupRepositoryProvider).fieldsForType(caseTypeId),
    );

final lookupItemProvider = FutureProvider.autoDispose
    .family<LookupItem?, String>(
      (ref, id) => ref.watch(lookupRepositoryProvider).byId(id),
    );
