"""تشغيل على سيرفر المكتب بضغطة واحدة: بلا قاعدة بيانات خارجية وبلا إعداد.

أول تشغيل:
  - ينشئ config.ini بقاعدة بيانات محلية (ملف SQLite داخل مجلد data)
  - ينشئ الجداول
  - يفتح المتصفح على صفحة إنشاء حساب مدير النظام (بالعربية)
ثم في كل مرة: يحدّث الجداول إن لزم، ويشغّل البرنامج ويفتح المتصفح.

يقبل الاتصال من أجهزة الشبكة الداخلية (بعد فتح المنفذ بـ open_firewall.cmd)،
ويطبع العنوان الذي يُكتب في متصفح الجهاز المجاور.
"""

from __future__ import annotations

import socket
import sys
import threading
import webbrowser

from app.config import BASE_DIR, DEFAULT_CONFIG_FILE, load_settings
from app.console import use_utf8_console

LOCAL_PORT = 8080


def ensure_config() -> None:
    if DEFAULT_CONFIG_FILE.exists():
        return
    data = BASE_DIR / "data"
    data.mkdir(exist_ok=True)
    db_path = (data / "field_cases.db").as_posix()
    DEFAULT_CONFIG_FILE.write_text(
        "; أُنشئ تلقائيًا للتشغيل على هذا الجهاز.\n"
        "; host = 0.0.0.0 يسمح بالدخول من أجهزة الشبكة. اجعله 127.0.0.1 لهذا الجهاز فقط.\n"
        "[server]\n"
        "host = 0.0.0.0\n"
        f"port = {LOCAL_PORT}\n"
        f"data_dir = {data.as_posix()}\n\n"
        "[database]\n"
        f"url = sqlite:///{db_path}\n\n"
        "[app]\n"
        "timezone = Asia/Riyadh\n",
        encoding="utf-8",
    )
    print("Created local settings (config.ini)")


def lan_addresses() -> list[str]:
    """عناوين هذا الجهاز في الشبكة الداخلية (لكتابتها في الجهاز المجاور)."""
    found: list[str] = []
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith("127.") and ip not in found:
                found.append(ip)
    except OSError:
        pass
    # احتياطي: عنوان الواجهة الافتراضية. UDP connect لا يرسل أي بيانات.
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.connect(("10.255.255.255", 1))
            ip = probe.getsockname()[0]
            if not ip.startswith("127.") and ip not in found:
                found.append(ip)
    except OSError:
        pass
    return found


def main() -> int:
    use_utf8_console()
    ensure_config()
    settings = load_settings()

    from manage import init_db

    init_db(settings.database_url)

    import uvicorn

    from app.main import create_app

    url = f"http://127.0.0.1:{settings.port}"
    # نص إنجليزي: نافذة الأوامر في Windows لا تعرض العربية بشكل صحيح.
    print()
    print("=" * 60)
    print("  Field Cases is running.")
    print(f"  On this computer:   {url}")
    if settings.host != "127.0.0.1":
        print("  From other computers on the office network:")
        for ip in lan_addresses() or ["<this computer's IP address>"]:
            print(f"                      http://{ip}:{settings.port}")
    print()
    print("  First time? The browser opens a page to create the admin account.")
    print("  Keep this window open. To stop: close it or press Ctrl+C.")
    print("=" * 60)
    threading.Timer(2.0, lambda: webbrowser.open(url)).start()
    uvicorn.run(
        create_app(settings),
        host=settings.host,
        port=settings.port,
        server_header=False,
        log_level="warning",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
