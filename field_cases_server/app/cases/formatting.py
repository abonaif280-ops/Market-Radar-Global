"""تنسيق عربي للتاريخ والوقت والإحداثيات — مطابق لتطبيق الجوال."""

from __future__ import annotations

import re
from datetime import datetime

WEEKDAYS = ["الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت", "الأحد"]


def time_12(local: datetime) -> str:
    """7:30 مساءً"""
    hour12 = 12 if local.hour % 12 == 0 else local.hour % 12
    period = "صباحًا" if local.hour < 12 else "مساءً"
    return f"{hour12}:{local.minute:02d} {period}"


def date(local: datetime) -> str:
    """25/09/2026"""
    return f"{local.day:02d}/{local.month:02d}/{local.year}"


def weekday(local: datetime) -> str:
    return WEEKDAYS[local.weekday()]


def date_time(local: datetime) -> str:
    return f"{date(local)} - {time_12(local)}"


_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹", "01234567890123456789")


def normalize_digits(value: str) -> str:
    return value.translate(_DIGITS)


def parse_coordinates(text: str) -> tuple[float, float] | None:
    """يقرأ "24.468245, 39.612354" ويقبل الأرقام العربية والفاصلة العربية."""
    normalized = normalize_digits(text).replace("،", ",").replace("٫", ".").strip()
    parts = [p for p in re.split(r"[,\s]+", normalized) if p]
    if len(parts) != 2:
        return None
    try:
        lat, lng = float(parts[0]), float(parts[1])
    except ValueError:
        return None
    if not (-90 <= lat <= 90 and -180 <= lng <= 180):
        return None
    return lat, lng


def format_coordinates(lat: float, lng: float) -> str:
    return f"{lat:.6f}, {lng:.6f}"


