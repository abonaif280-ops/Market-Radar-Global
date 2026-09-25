import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/db/audit_logger.dart';
import '../core/files/attachment_storage.dart';
import '../core/location/location_service.dart';
import '../core/crypto/key_manager.dart';
import '../core/platform/map_launcher.dart';
import '../core/security/pin_hasher.dart';
import '../core/security/secret_store.dart';
import '../core/platform/photo_picker.dart';
import '../core/platform/share_service.dart';
import '../features/cases/data/cases_repository.dart';
import '../features/cases/domain/case_enums.dart';
import '../features/cases/domain/case_type_field.dart';
import '../features/cases/domain/case_views.dart';
import '../features/export/data/case_export_service.dart';
import '../features/import/data/import_service.dart';
import '../features/import/data/version_resolution_service.dart';
import '../features/settings/data/lookup_repository.dart';
import '../features/supervisor/data/inbox_repository.dart';
import '../features/supervisor/data/role_service.dart';
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

/// مجلد ملفات التصدير المؤقتة؛ يُستبدل في main() وفي الاختبارات.
final exportDirectoryProvider = Provider<Directory>(
  (ref) =>
      throw UnimplementedError('exportDirectoryProvider must be overridden'),
);

final caseExportServiceProvider = Provider<CaseExportService>(
  (ref) => CaseExportService(
    ref.watch(appDatabaseProvider),
    storage: ref.watch(attachmentStorageProvider),
    settings: ref.watch(settingsRepositoryProvider),
    audit: ref.watch(auditLoggerProvider),
    keys: ref.watch(keyManagerProvider),
    outputDirectory: ref.watch(exportDirectoryProvider),
  ),
);

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const DeviceSecretStore(),
);

final pinHasherProvider = Provider<PinHasher>((ref) => PinHasher());

final keyManagerProvider = Provider<KeyManager>(
  (ref) => KeyManager(
    secrets: ref.watch(secretStoreProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final roleServiceProvider = Provider<RoleService>(
  (ref) => RoleService(
    settings: ref.watch(settingsRepositoryProvider),
    secrets: ref.watch(secretStoreProvider),
    hasher: ref.watch(pinHasherProvider),
    keys: ref.watch(keyManagerProvider),
    audit: ref.watch(auditLoggerProvider),
  ),
);

/// مجلد الحزم الواردة (داخل مساحة التطبيق)؛ يُستبدل في main() وفي الاختبارات.
final importDirectoryProvider = Provider<Directory>(
  (ref) =>
      throw UnimplementedError('importDirectoryProvider must be overridden'),
);

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(
    ref.watch(appDatabaseProvider),
    storage: ref.watch(attachmentStorageProvider),
    settings: ref.watch(settingsRepositoryProvider),
    audit: ref.watch(auditLoggerProvider),
    keys: ref.watch(keyManagerProvider),
    workDirectory: ref.watch(importDirectoryProvider),
  ),
);

final versionResolutionProvider = Provider<VersionResolutionService>(
  (ref) => VersionResolutionService(
    ref.watch(appDatabaseProvider),
    storage: ref.watch(attachmentStorageProvider),
    settings: ref.watch(settingsRepositoryProvider),
    audit: ref.watch(auditLoggerProvider),
    workDirectory: ref.watch(importDirectoryProvider),
  ),
);

/// النسخ الواردة التي تنتظر القرار؛ null = كل الدفعات.
final pendingVersionsProvider =
    StreamProvider.family<List<PendingVersion>, String?>(
      (ref, batchId) =>
          ref.watch(versionResolutionProvider).watchPending(batchId: batchId),
    );

final caseVersionsProvider =
    StreamProvider.family<List<CaseVersionEntry>, String>(
      (ref, caseId) =>
          ref.watch(versionResolutionProvider).watchVersions(caseId),
    );

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(
    ref.watch(appDatabaseProvider),
    audit: ref.watch(auditLoggerProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final inboxBatchesProvider = StreamProvider<List<InboxBatch>>(
  (ref) => ref.watch(inboxRepositoryProvider).watchBatches(),
);

final pendingReviewCountProvider = StreamProvider<int>(
  (ref) => ref.watch(inboxRepositoryProvider).watchPendingCount(),
);

/// يُعاد حسابه عند أي تغيير في الحالات.
final todayStatsProvider = StreamProvider<TodayStats>((ref) async* {
  final inbox = ref.watch(inboxRepositoryProvider);
  yield await inbox.todayStats();
  await for (final _ in ref.watch(casesRepositoryProvider).watchChanges()) {
    yield await inbox.todayStats();
  }
});

final supervisorPublicKeyProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(keyManagerProvider).supervisorPublicKey(),
);

/// لدى الموظف: مفتاح المشرف الذي تُشفَّر له الحزم.
final recipientKeyProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(keyManagerProvider).recipientKey(),
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
