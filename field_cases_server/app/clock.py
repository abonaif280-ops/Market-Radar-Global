from __future__ import annotations

from datetime import datetime, timezone


def utcnow() -> datetime:
    """الوقت الحالي UTC بدون منطقة زمنية (الصيغة المخزنة في القاعدة)."""
    return datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)
