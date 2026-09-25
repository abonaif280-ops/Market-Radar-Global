/// نتيجة التحقق من رمز PIN.
sealed class PinCheck {
  const PinCheck();
}

class PinAccepted extends PinCheck {
  const PinAccepted();
}

class PinRejected extends PinCheck {
  const PinRejected(this.remainingAttempts);

  final int remainingAttempts;
}

class PinLockedOut extends PinCheck {
  const PinLockedOut(this.retryAfter);

  final Duration retryAfter;
}

/// يحد من محاولات إدخال الرمز: بعد [maxAttempts] محاولات خاطئة قفل مؤقت.
class PinAttemptGuard {
  PinAttemptGuard({
    this.maxAttempts = 5,
    this.lockDuration = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxAttempts;
  final Duration lockDuration;
  final DateTime Function() _clock;

  int _failed = 0;
  DateTime? _lockedUntil;

  /// [verify] يُستدعى فقط إذا لم يكن الإدخال مقفلًا.
  Future<PinCheck> check(Future<bool> Function() verify) async {
    final now = _clock();
    if (_lockedUntil != null && now.isBefore(_lockedUntil!)) {
      return PinLockedOut(_lockedUntil!.difference(now));
    }
    if (await verify()) {
      _failed = 0;
      _lockedUntil = null;
      return const PinAccepted();
    }
    _failed++;
    if (_failed >= maxAttempts) {
      _failed = 0;
      _lockedUntil = now.add(lockDuration);
      return PinLockedOut(lockDuration);
    }
    return PinRejected(maxAttempts - _failed);
  }
}
