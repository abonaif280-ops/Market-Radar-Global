import 'dart:convert';
import 'dart:io';

import 'package:field_cases/core/crypto/key_manager.dart';
import 'package:field_cases/core/crypto/package_cipher.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/export/data/case_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_device.dart';

void main() {
  late Directory temp;
  late TestDevice employee;
  late TestDevice supervisor;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('enc_import');
    employee = TestDevice(Directory(p.join(temp.path, 'e')), 'شرطة ينبع');
    supervisor = TestDevice(Directory(p.join(temp.path, 's')), 'إدارة المنطقة');
    await employee.init();
    await supervisor.init();
  });
  tearDown(() async {
    await employee.db.close();
    await supervisor.db.close();
    await temp.delete(recursive: true);
  });

  /// تسليم المفتاح العام حضوريًا (QR) من المشرف إلى الموظف.
  Future<RecipientKey> handOverKey() async {
    final public = await supervisor.keys.ensureSupervisorKeys();
    final payload = RecipientKey(public, label: 'إدارة المنطقة').toPayload();
    final scanned = RecipientKey.tryParse(payload)!;
    await employee.keys.setRecipientKey(scanned);
    return scanned;
  }

  test(
    'employee package is encrypted for the supervisor and imported',
    () async {
      final key = await handOverKey();
      final id = await employee.addCase(photos: 1);

      final preview = await employee.exporter.preview(
        const ExportRequest.unexported(),
      );
      expect(preview.recipient!.fingerprint, key.fingerprint);

      final result = await employee.exporter.export(
        const ExportRequest.unexported(),
      );
      expect(result.encryptedFor!.label, 'إدارة المنطقة');
      expect(await PackageCipher.isEnvelope(result.file), isTrue);

      // لا شيء مقروء داخل الملف: لا ZIP ولا نص الحالة ولا أسماء الملفات.
      final bytes = await result.file.readAsBytes();
      final latin = latin1.decode(bytes, allowInvalid: true);
      expect(latin.contains('manifest.json'), isFalse);
      expect(latin.contains('cases.json'), isFalse);
      expect(latin.contains('EVT-'), isFalse);
      final utf = utf8.decode(bytes, allowMalformed: true);
      expect(utf.contains('الرايس'), isFalse);
      // لا يبقى ملف غير مشفر في مجلد التصدير.
      expect(
        Directory(p.join(employee.root.path, 'exports'))
            .listSync()
            .whereType<File>()
            .map((f) => f.path),
        [result.file.path],
      );

      final report = await supervisor.importer.prepare(result.file.path);
      expect(report.errors, isEmpty);
      expect(report.wasEncrypted, isTrue);
      await supervisor.importer.commit(report);
      final imported = (await supervisor.cases.watchDetails(id).first)!;
      expect(imported.displayStatus, DisplayStatus.imported);
      expect(imported.attachments, hasLength(1));
    },
  );

  test('a different supervisor cannot import it', () async {
    await handOverKey();
    await employee.addCase();
    final result = await employee.exporter.export(
      const ExportRequest.unexported(),
    );

    final other = TestDevice(Directory(p.join(temp.path, 'o')), 'جهة أخرى');
    await other.keys.ensureSupervisorKeys();
    final report = await other.importer.prepare(result.file.path);
    expect(report.canImport, isFalse);
    expect(report.errors.single, contains('مشرف آخر'));
    await other.db.close();
  });

  test('device without supervisor keys explains how to open it', () async {
    await handOverKey();
    await employee.addCase();
    final result = await employee.exporter.export(
      const ExportRequest.unexported(),
    );

    final plainDevice = TestDevice(Directory(p.join(temp.path, 'x')), 'جهاز');
    final report = await plainDevice.importer.prepare(result.file.path);
    expect(report.errors.single, contains('فعّل وضع المشرف'));
    await plainDevice.db.close();
  });

  test('without a recipient key the package is plain and flagged', () async {
    await employee.addCase();
    final preview = await employee.exporter.preview(
      const ExportRequest.unexported(),
    );
    expect(preview.recipient, isNull);
    final result = await employee.exporter.export(
      const ExportRequest.unexported(),
    );
    expect(result.encryptedFor, isNull);
    expect(await PackageCipher.isEnvelope(result.file), isFalse);
  });

  test(
    'newer versions from encrypted packages can still be compared',
    () async {
      await handOverKey();
      final id = await employee.addCase();
      final first = await employee.exporter.export(
        const ExportRequest.unexported(),
      );
      await supervisor.importer.commit(
        await supervisor.importer.prepare(first.file.path),
      );

      final form = await employee.cases.loadForm(id)
        ..notes = 'تحديث';
      await employee.cases.updateCase(id, form, status: CaseStatus.completed);
      final second = await employee.exporter.export(ExportRequest.single(id));
      await supervisor.importer.commit(
        await supervisor.importer.prepare(second.file.path),
      );

      final cmp = await supervisor.versions.compare(
        second.manifest.packageId,
        id,
      );
      expect(cmp.changedFields.map((f) => f.label), contains('ملاحظات'));
    },
  );
}
