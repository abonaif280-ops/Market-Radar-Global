import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:field_cases/core/files/attachment_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late AttachmentStorage storage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('storage_test');
    storage = AttachmentStorage(Directory(p.join(temp.path, 'app')));
  });
  tearDown(() => temp.delete(recursive: true));

  Future<File> writeImage(
    String name, {
    int width = 1200,
    int height = 900,
  }) async {
    final file = File(p.join(temp.path, 'src', name));
    await file.create(recursive: true);
    final image = img.Image(width: width, height: height)
      ..clear(img.ColorRgb8(10, 200, 30));
    await file.writeAsBytes(
      name.endsWith('.png') ? img.encodePng(image) : img.encodeJpg(image),
    );
    return file;
  }

  test('staging copies the image, hashes it and builds a thumbnail', () async {
    final source = await writeImage('photo.jpg');
    final staged = await storage.stageImage(source.path);

    expect(staged.isNew, isTrue);
    expect(staged.filePath, contains(p.join('app', 'staging')));
    expect(
      staged.sha256,
      sha256.convert(await source.readAsBytes()).toString(),
    );
    expect(staged.sizeBytes, await source.length());
    expect(staged.mimeType, 'image/jpeg');
    expect((staged.width, staged.height), (1200, 900));

    final thumb = img.decodeJpg(await File(staged.thumbPath!).readAsBytes())!;
    expect(thumb.width, AttachmentStorage.thumbnailWidth);
    expect(source.existsSync(), isTrue);
  });

  test('camera temp files can be deleted after staging', () async {
    final source = await writeImage('camera.JPEG');
    final staged = await storage.stageImage(source.path, deleteSource: true);
    expect(source.existsSync(), isFalse);
    expect(staged.filePath, endsWith('.jpg'));
  });

  test('unsupported formats are kept without a thumbnail', () async {
    final source = File(p.join(temp.path, 'src', 'photo.heic'));
    await source.create(recursive: true);
    await source.writeAsBytes(List.filled(64, 7));
    final staged = await storage.stageImage(source.path);
    expect(staged.thumbPath, isNull);
    expect(staged.previewPath, staged.filePath);
    expect(staged.mimeType, 'image/heic');
  });

  test('missing source file reports a clear error', () async {
    expect(
      () => storage.stageImage(p.join(temp.path, 'nope.jpg')),
      throwsA(isA<AttachmentStorageException>()),
    );
  });

  test('commit moves files and rollback restores them', () async {
    final staged = await storage.stageImage((await writeImage('a.png')).path);
    final committed = await storage.commit(
      staged,
      caseId: 'case-1',
      fileName: 'EVT-20260925-A72F91_001.png',
    );

    expect(
      committed.relativePath,
      p.join('attachments', 'case-1', 'EVT-20260925-A72F91_001.png'),
    );
    expect(File(storage.absolute(committed.relativePath)).existsSync(), isTrue);
    expect(
      File(storage.absolute(committed.thumbRelativePath!)).existsSync(),
      isTrue,
    );
    expect(File(staged.filePath).existsSync(), isFalse);

    await storage.rollback([committed]);
    expect(File(staged.filePath).existsSync(), isTrue);
    expect(File(staged.thumbPath!).existsSync(), isTrue);
    expect(
      File(storage.absolute(committed.relativePath)).existsSync(),
      isFalse,
    );
  });

  test('discard and clearStaging remove unsaved photos only', () async {
    final a = await storage.stageImage((await writeImage('a.jpg')).path);
    final b = await storage.stageImage((await writeImage('b.jpg')).path);

    await storage.discardStaged([a]);
    expect(File(a.filePath).existsSync(), isFalse);
    expect(File(b.filePath).existsSync(), isTrue);

    await storage.clearStaging();
    expect(File(b.filePath).existsSync(), isFalse);
  });
}
