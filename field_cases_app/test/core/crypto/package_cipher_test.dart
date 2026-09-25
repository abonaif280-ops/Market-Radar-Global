import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:field_cases/core/crypto/key_manager.dart';
import 'package:field_cases/core/crypto/package_cipher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late SimpleKeyPair supervisor;
  late List<int> supervisorPublic;
  final cipher = PackageCipher();

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cipher_test');
    supervisor = await X25519().newKeyPair();
    supervisorPublic = (await supervisor.extractPublicKey()).bytes;
  });
  tearDown(() => temp.delete(recursive: true));

  File f(String name) => File(p.join(temp.path, name));

  Future<File> sample(int size) async {
    final rnd = Random(7);
    final file = f('plain.bin');
    await file.writeAsBytes(List<int>.generate(size, (_) => rnd.nextInt(256)));
    return file;
  }

  Future<File> encrypt(File input, {int chunkSize = 1000}) async {
    final out = f('enc.casepkg');
    await cipher.encryptFile(
      input: input,
      output: out,
      recipientPublicKey: supervisorPublic,
      chunkSize: chunkSize,
    );
    return out;
  }

  Future<void> decryptTo(File input, File output, [SimpleKeyPair? keyPair]) =>
      cipher.decryptFile(
        input: input,
        output: output,
        recipientKeyPair: keyPair ?? supervisor,
      );

  test('round trip across many chunks, partial last chunk', () async {
    final plain = await sample(5500);
    final enc = await encrypt(plain);
    expect(await PackageCipher.isEnvelope(enc), isTrue);
    expect(await PackageCipher.isEnvelope(plain), isFalse);

    final out = f('out.bin');
    await decryptTo(enc, out);
    expect(await out.readAsBytes(), await plain.readAsBytes());
    expect(f('enc.casepkg.partial').existsSync(), isFalse);
  });

  test('exact multiple of chunk size and empty file', () async {
    for (final size in [3000, 0]) {
      final plain = await sample(size);
      final enc = await encrypt(plain);
      final out = f('out_$size.bin');
      await decryptTo(enc, out);
      expect(
        await out.readAsBytes(),
        await plain.readAsBytes(),
        reason: '$size',
      );
    }
  });

  test('header names the recipient but contains no secret', () async {
    final enc = await encrypt(await sample(100));
    final header = await cipher.readHeader(enc);
    expect(
      header.recipientKeyId,
      SupervisorPublicKey.fingerprintOf(supervisorPublic),
    );
    expect(header.ephemeralPublicKey, hasLength(32));
    expect(header.ephemeralPublicKey, isNot(supervisorPublic));
    // تشفيران لنفس الملف مختلفان تمامًا (مفتاح مؤقت وملح جديدان).
    final first = await enc.readAsBytes();
    final again = await encrypt(await sample(100));
    expect(await again.readAsBytes(), isNot(first));
  });

  test('another supervisor cannot open it', () async {
    final enc = await encrypt(await sample(2000));
    final other = await X25519().newKeyPair();
    final out = f('out.bin');
    await expectLater(
      decryptTo(enc, out, other),
      throwsA(
        isA<PackageCipherException>().having(
          (e) => e.message,
          'message',
          contains('مشرف آخر'),
        ),
      ),
    );
    expect(out.existsSync(), isFalse);
  });

  group('tampering is detected', () {
    Future<void> expectRejected(List<int> Function(List<int>) change) async {
      final enc = await encrypt(await sample(4500));
      final bytes = change(await enc.readAsBytes());
      final bad = f('bad.casepkg')..writeAsBytesSync(bytes);
      final out = f('out.bin');
      await expectLater(
        decryptTo(bad, out),
        throwsA(isA<PackageCipherException>()),
      );
      expect(out.existsSync(), isFalse, reason: 'لا يبقى ناتج جزئي');
    }

    test(
      'flipped byte in the data',
      () => expectRejected((b) {
        final copy = [...b];
        copy[copy.length - 100] ^= 0x01;
        return copy;
      }),
    );

    test(
      'truncated (last chunk removed)',
      () => expectRejected((b) => b.sublist(0, b.length - (500 + 16))),
    );

    test('extra bytes appended', () => expectRejected((b) => [...b, 1, 2, 3]));

    test(
      'header altered',
      () => expectRejected((b) {
        final copy = [...b];
        // داخل JSON الرأس بعد البادئة (8 + 2 + 4).
        final i = copy.indexOf('"'.codeUnitAt(0), 14 + 10);
        copy[i + 1] ^= 0x20;
        return copy;
      }),
    );

    test('not an envelope at all', () => expectRejected((b) => [1, 2, 3, 4]));
  });

  group('RecipientKey payload (QR / pasted text)', () {
    test('round trip with label', () {
      final key = RecipientKey(
        SupervisorPublicKey(supervisorPublic),
        label: 'إدارة | المنطقة',
      );
      final parsed = RecipientKey.tryParse(key.toPayload())!;
      expect(parsed.publicKey.bytes, supervisorPublic);
      expect(parsed.label, 'إدارة   المنطقة');
      expect(parsed.fingerprint, key.fingerprint);
    });

    test('rejects invalid payloads', () {
      for (final bad in [
        '',
        'hello',
        'FCKEY1|',
        'FCKEY1|!!!',
        'FCKEY1|AAAA',
        'OTHER|${'A' * 44}',
      ]) {
        expect(RecipientKey.tryParse(bad), isNull, reason: bad);
      }
    });
  });
}
