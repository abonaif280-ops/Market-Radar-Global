import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/audit_logger.dart';
import '../../../core/utils/arabic_format.dart';
import '../../import/data/version_resolution_service.dart';

/// "سجل العمليات": قراءة فقط، الأحدث أولًا، بصفحات.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  static const int pageSize = 50;

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _entries = <AuditLogData>[];
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await ref
        .read(auditLoggerProvider)
        .recent(limit: AuditLogScreen.pageSize, offset: _entries.length);
    if (!mounted) return;
    setState(() {
      _entries.addAll(page);
      _hasMore = page.length == AuditLogScreen.pageSize;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      body: _entries.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const Center(child: Text('لا توجد عمليات مسجلة'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _entries.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == _entries.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: _loadMore,
                              child: const Text('عرض المزيد'),
                            ),
                    ),
                  );
                }
                final e = _entries[i];
                final (label, icon) = AuditLabels.of(e.action);
                final summary = AuditLabels.summary(e.detailsJson);
                return ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  // الملخص (أرقام حالات لاتينية) في سطر مستقل حتى لا يختلط
                  // اتجاه النص العربي باللاتيني.
                  subtitle: Text(
                    [
                      [
                        ArabicFormat.dateTime(e.at.toLocal()),
                        if (e.actor != null && e.actor!.isNotEmpty) e.actor!,
                      ].join(' • '),
                      if (summary.isNotEmpty) summary,
                    ].join('\n'),
                    style: TextStyle(color: muted),
                  ),
                );
              },
            ),
    );
  }
}

/// أسماء العمليات بالعربية وملخص تفاصيلها.
abstract final class AuditLabels {
  static (String, IconData) of(String action) => switch (action) {
    AuditActions.caseCreated => ('إنشاء حالة', Icons.add_circle_outline),
    AuditActions.caseUpdated => ('تعديل حالة', Icons.edit_outlined),
    AuditActions.caseDeleted => ('حذف حالة (للمحذوفات)', Icons.delete_outline),
    AuditActions.caseRestored => ('استعادة حالة محذوفة', Icons.restore),
    AuditActions.casePurged => ('حذف نهائي لحالة', Icons.delete_forever),
    AuditActions.attachmentAdded => ('إضافة صورة', Icons.add_a_photo_outlined),
    AuditActions.attachmentDeleted => ('حذف صورة', Icons.hide_image_outlined),
    AuditActions.packageExported => ('تصدير حزمة', Icons.ios_share),
    AuditActions.batchImported => ('استيراد دفعة', Icons.move_to_inbox),
    AuditActions.caseApproved => ('اعتماد حالة', Icons.verified_outlined),
    AuditActions.caseRejected => ('رفض حالة', Icons.block),
    AuditActions.roleChanged => (
      'تغيير الدور',
      Icons.admin_panel_settings_outlined,
    ),
    AuditActions.appLockChanged => ('إعدادات قفل التطبيق', Icons.lock_outline),
    AuditActions.backupCreated => (
      'إنشاء نسخة احتياطية',
      Icons.backup_outlined,
    ),
    AuditActions.backupRestored => (
      'استعادة نسخة احتياطية',
      Icons.settings_backup_restore,
    ),
    VersionResolutionService.versionKept => (
      'إبقاء النسخة الحالية',
      Icons.compare_arrows,
    ),
    VersionResolutionService.versionReplaced => (
      'استبدال بنسخة أحدث',
      Icons.compare_arrows,
    ),
    VersionResolutionService.versionArchived => (
      'الاحتفاظ بالنسختين',
      Icons.compare_arrows,
    ),
    _ => (action, Icons.info_outline),
  };

  /// أهم التفاصيل فقط (رقم الحالة، الأعداد) — دون عرض JSON خام.
  static String summary(String? detailsJson) {
    if (detailsJson == null) return '';
    try {
      final d = jsonDecode(detailsJson);
      if (d is! Map) return '';
      final parts = <String>[
        if (d['display_code'] is String) d['display_code'] as String,
        if (d['cases'] is num) '${d['cases']} حالة',
        if (d['case_count'] is num) '${d['case_count']} حالة',
        if (d['role'] == 'supervisor') 'مشرف',
        if (d['role'] == 'employee') 'موظف',
      ];
      return parts.join(' • ');
    } on FormatException {
      return '';
    }
  }
}
