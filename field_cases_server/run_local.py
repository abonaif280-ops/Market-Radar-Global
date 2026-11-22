"""تشغيل على سيرفر المكتب بضغطة واحدة: بلا قاعدة بيانات خارجية وبلا إعداد.

أول تشغيل:
  - ينشئ config.ini بقاعدة بيانات محلية (ملف SQLite داخل مجلد data)
  - ينشئ الجداول
  - يطلب اسم مدير النظام وكلمة مروره
ثم في كل مرة: يحدّث الجداول إن لزم، ويشغّل البرنامج ويفتح المتصفح.

يقبل الاتصال من أجهزة الشبكة الداخلية (بعد فتح المنفذ بـ open_firewall.cmd)،
ويطبع العنوان الذي يُكتب في متصفح الجهاز المجاور.
"""

from __future__ import annotations

import getpass
import socket
import sys
import threading
import webbrowser

from sqlalchemy import func, select

from app.config import BASE_DIR, DEFAULT_CONFIG_FILE, load_settings
from app.console import use_utf8_console
from app.db import make_engine, make_session_factory, session_scope
from app.models import User

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
    print("أُنشئت الإعدادات المحلية (config.ini)")


def has_users(database_url: str) -> bool:
    engine = make_engine(database_url)
    try:
        with session_scope(make_session_factory(engine)) as db:
            return (db.scalar(select(func.count()).select_from(User)) or 0) > 0
    finally:
        engine.dispose()


def ask_admin(database_url: str) -> None:
    from app import security
    from manage import create_admin

    print()
    print("=== إنشاء حساب مدير النظام (مرة واحدة) ===")
    while True:
        username = security.normalize_username(input("اسم المستخدم (أحرف إنجليزية وأرقام، مثل admin): "))
        error = security.validate_username(username)
        if error:
            print(error)
            continue
        break
    full_name = input("الاسم الكامل: ").strip() or "مدير النظام"
    while True:
        password = getpass.getpass("كلمة المرور (10 أحرف على الأقل، حروف وأرقام): ")
        error = security.validate_password(password, username)
        if error:
            print(error)
            continue
        if getpass.getpass("أعد كلمة المرور: ") != password:
            print("كلمتا المرور غير متطابقتين")
            continue
        break
    create_admin(database_url, username, full_name, password)
    print(f"أُنشئ الحساب: {username}")


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
    if not has_users(settings.database_url):
        ask_admin(settings.database_url)

    import uvicorn

    from app.main import create_app

    url = f"http://127.0.0.1:{settings.port}"
    print()
    print(f"البرنامج يعمل. على هذا الجهاز: {url}")
    if settings.host != "127.0.0.1":
        addresses = lan_addresses()
        print("من الجهاز المجاور في نفس الشبكة اكتب في المتصفح:")
        for ip in addresses or ["<عنوان هذا الجهاز>"]:
            print(f"    http://{ip}:{settings.port}")
        print(f"    أو http://{socket.gethostname()}:{settings.port}")
        print("إن لم يفتح: شغّل open_firewall.cmd مرة واحدة لفتح المنفذ في جدار الحماية.")
    print("اترك هذه النافذة مفتوحة أثناء الاستخدام. للإيقاف: أغلقها أو اضغط Ctrl+C")
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
