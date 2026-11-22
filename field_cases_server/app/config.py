"""الإعدادات من ملف config.ini بجانب البرنامج، مع إمكانية التجاوز بمتغيرات البيئة.

لا توجد أي قيم سرية في الكود. كلمة مرور قاعدة البيانات تُكتب في config.ini
(يُحمى بصلاحيات ملفات Windows) أو في متغير البيئة FC_DATABASE_URL.
"""

from __future__ import annotations

import configparser
import os
from dataclasses import dataclass
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG_FILE = BASE_DIR / "config.ini"


class ConfigError(Exception):
    """إعداد ناقص أو غير صالح؛ الرسالة موجهة لمدير النظام."""


@dataclass(frozen=True)
class Settings:
    host: str
    port: int
    database_url: str
    tls_cert_file: str | None
    tls_key_file: str | None
    session_idle_minutes: int
    session_max_hours: int
    max_login_attempts: int
    lockout_minutes: int
    data_dir: Path
    timezone: str = "Asia/Riyadh"

    @property
    def https(self) -> bool:
        return bool(self.tls_cert_file and self.tls_key_file)

    @property
    def tz(self) -> ZoneInfo:
        return ZoneInfo(self.timezone)


def load_settings(path: Path | None = None) -> Settings:
    # الأولوية: المسار المُمرَّر (manage.py --config) ثم FC_CONFIG ثم config.ini بجانب البرنامج.
    path = Path(path) if path else Path(os.environ.get("FC_CONFIG") or DEFAULT_CONFIG_FILE)
    parser = configparser.ConfigParser(interpolation=None)
    if path.exists():
        parser.read(path, encoding="utf-8-sig")  # Windows قد يضيف BOM

    def get(section: str, key: str, env: str, default: str | None = None) -> str | None:
        value = os.environ.get(env)
        if value is None:
            value = parser.get(section, key, fallback=default)
        if value is not None:
            value = value.strip()
        return value or default

    database_url = get("database", "url", "FC_DATABASE_URL")
    if not database_url:
        raise ConfigError(
            f"لم يُحدَّد رابط قاعدة البيانات. انسخ config.example.ini إلى {path.name} "
            "واكتب [database] url."
        )

    def get_int(section: str, key: str, env: str, default: int, low: int, high: int) -> int:
        raw = get(section, key, env, str(default))
        try:
            value = int(raw)  # type: ignore[arg-type]
        except ValueError as e:
            raise ConfigError(f"[{section}] {key} يجب أن يكون رقمًا") from e
        if not low <= value <= high:
            raise ConfigError(f"[{section}] {key} يجب أن يكون بين {low} و {high}")
        return value

    cert = get("server", "tls_cert_file", "FC_TLS_CERT_FILE")
    key = get("server", "tls_key_file", "FC_TLS_KEY_FILE")
    if bool(cert) != bool(key):
        raise ConfigError("لتفعيل HTTPS يجب تحديد tls_cert_file و tls_key_file معًا")

    data_dir = Path(get("server", "data_dir", "FC_DATA_DIR", str(BASE_DIR / "data")))  # type: ignore[arg-type]
    timezone = get("app", "timezone", "FC_TIMEZONE", "Asia/Riyadh")
    try:
        ZoneInfo(timezone)  # type: ignore[arg-type]
    except (ZoneInfoNotFoundError, ValueError) as e:
        raise ConfigError(f"[app] timezone غير معروف: {timezone}") from e
    return Settings(
        host=get("server", "host", "FC_HOST", "0.0.0.0"),  # type: ignore[arg-type]
        port=get_int("server", "port", "FC_PORT", 8080, 1, 65535),
        database_url=database_url,
        tls_cert_file=cert,
        tls_key_file=key,
        session_idle_minutes=get_int("security", "session_idle_minutes", "FC_SESSION_IDLE", 30, 5, 600),
        session_max_hours=get_int("security", "session_max_hours", "FC_SESSION_MAX", 12, 1, 72),
        max_login_attempts=get_int("security", "max_login_attempts", "FC_MAX_ATTEMPTS", 5, 3, 20),
        lockout_minutes=get_int("security", "lockout_minutes", "FC_LOCKOUT", 15, 1, 1440),
        data_dir=data_dir,
        timezone=timezone,  # type: ignore[arg-type]
    )
