"""تشغيل السيرفر على المنفذ المحدد في config.ini (الافتراضي 8080).

من جهاز آخر في الشبكة: http://<اسم أو عنوان السيرفر>:<المنفذ>
(https:// عند تفعيل الشهادة).
"""

from __future__ import annotations

import sys

import uvicorn

from app.console import use_utf8_console
from app.config import ConfigError, load_settings
from app.main import create_app


def main() -> int:
    use_utf8_console()
    try:
        settings = load_settings()
    except ConfigError as e:
        print(e, file=sys.stderr)
        return 2
    scheme = "https" if settings.https else "http"
    print(f"الحالات الميدانية تعمل على {scheme}://{settings.host}:{settings.port}")
    uvicorn.run(
        create_app(settings),
        host=settings.host,
        port=settings.port,
        ssl_certfile=settings.tls_cert_file,
        ssl_keyfile=settings.tls_key_file,
        proxy_headers=False,
        server_header=False,
        log_level="info",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
