import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/db/audit_logger.dart';
import '../core/files/attachment_storage.dart';
import '../core/location/location_service.dart';
import '../core/platform/map_launcher.dart';
import '../core/platform/photo_picker.dart';
import '../core/platform/share_service.dart';
import '../features/cases/data/cases_repository.dart';
import '../features/cases/domain/case_enums.dart';
import '../features/cases/domain/case_type_field.dart';
import '../features/cases/domain/case_views.dart';
import '../features/settings/data/lookup_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/templates/data/case_text_composer.dart';
import '../features/templates/data/template_repository.dart';

/// تُستبدل في main() بالقاعدة الفعلية، وفي الاختبارات بقاعدة في الذاكرة.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

/// تُستبدل في main() بمجلد التطبيق الخاص، وفي الاختبارات بمجلد مؤقت.
final attachmentStorageProvider = Provider<AttachmentStorage>(
  (ref) =>
      throw UnimplementedError('attachmentStorageProvider must be overridden'),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final mapLauncherProvider = Provider<MapLauncher>(
  (ref) => const SystemMapLauncher(),
);

final photoPickerProvider = Provider<PhotoPicker>((ref) => SystemPhotoPicker());

final shareServiceProvider = Provider<ShareService>(
  (ref) => const SystemShareService(),
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository(ref.watch(appDatabaseProvider)),
);

final caseTextComposerProvider = Provider<CaseTextComposer>(
  (ref) => CaseTextComposer(
    lookups: ref.watch(lookupRepositoryProvider),
    templates: ref.watch(templateRepositoryProvider),
  ),
);

final templatesListProvider = StreamProvider<List<TemplateListItem>>(
  (ref) => ref.watch(templateRepositoryProvider).watchAll(),
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
    storage: ref.watch(attachmentStorageProvider),
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
