import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/crypto/key_manager.dart';

/// لدى المشرف: عرض المفتاح العام كرمز QR ليمسحه الموظف حضوريًا.
///
/// المفتاح العام ليس سرًا (يُستخدم للتشفير فقط)، لكن تسليمه حضوريًا ومطابقة
/// البصمة يمنعان استبداله بمفتاح شخص آخر.
class SupervisorKeyQrScreen extends ConsumerWidget {
  const SupervisorKeyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicKey = ref.watch(supervisorPublicKeyProvider).value;
    final orgName = ref.watch(orgNameProvider).value;
    final scheme = Theme.of(context).colorScheme;

    if (publicKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مفتاح المشرف')),
        body: const Center(child: Text('فعّل وضع المشرف أولًا')),
      );
    }
    final payload = RecipientKey(
      publicKey,
      label: (orgName?.trim().isEmpty ?? true) ? null : orgName!.trim(),
    ).toPayload();

    return Scaffold(
      appBar: AppBar(title: const Text('مفتاح المشرف')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'اطلب من الموظف فتح: الإعدادات ← مفتاح التشفير ← مسح رمز QR',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(data: payload, size: 260),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'البصمة',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          SelectableText(
            publicKey.fingerprint,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'يجب أن تظهر نفس البصمة على جوال الموظف بعد المسح.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref
                .read(shareServiceProvider)
                .shareText(payload, subject: 'مفتاح المشرف'),
            icon: const Icon(Icons.share),
            label: const Text('مشاركة المفتاح كنص'),
          ),
        ],
      ),
    );
  }
}
