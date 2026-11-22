"""أوامر الإدارة على السيرفر (تُشغَّل من سطر الأوامر على السيرفر فقط).

  python manage.py check-db         فحص الاتصال بقاعدة البيانات
  python manage.py init-db          إنشاء الجداول أو ترقيتها لآخر إصدار
  python manage.py create-admin     إنشاء أول مدير نظام
  python manage.py reset-password   إعادة تعيين كلمة مرور مستخدم (عند فقدان المدير لكلمته)
"""

from __future__ import annotations

import argparse
import getpass
import sys
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import select, text

from app import audit, security
from app.audit import AuditAction
from app.clock import utcnow
from app.console import use_utf8_console
from app.config import BASE_DIR, ConfigError, load_settings
from app.db import make_engine, make_session_factory, session_scope
from app.models import Role, User


def alembic_config(database_url: str) -> Config:
    cfg = Config(str(BASE_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(BASE_DIR / "migrations"))
    cfg.attributes["database_url"] = database_url
    return cfg


def init_db(database_url: str) -> None:
    command.upgrade(alembic_config(database_url), "head")


def _ask_password(username: str) -> str:
    while True:
        first = getpass.getpass("كلمة المرور: ")
        error = security.validate_password(first, username)
        if error:
            print(error)
            continue
        if getpass.getpass("تأكيد كلمة المرور: ") != first:
            print("كلمتا المرور غير متطابقتين")
            continue
        return first


def create_admin(database_url: str, username: str, full_name: str, password: str) -> None:
    username = security.normalize_username(username)
    error = security.validate_username(username) or security.validate_password(password, username)
    if error:
        raise SystemExit(error)
    factory = make_session_factory(make_engine(database_url))
    with session_scope(factory) as db:
        if db.scalar(select(User).where(User.username == username)):
            raise SystemExit("اسم المستخدم موجود من قبل")
        now = utcnow()
        user = User(
            username=username,
            full_name=full_name,
            role=Role.ADMIN,
            password_hash=security.hash_password(password),
            is_active=True,
            must_change_password=False,
            failed_attempts=0,
            created_at=now,
            updated_at=now,
        )
        db.add(user)
        db.flush()
        audit.log(
            db,
            AuditAction.USER_CREATED,
            username="(سطر الأوامر)",
            entity_type="user",
            entity_id=user.id,
            details={"username": username, "role": Role.ADMIN},
        )


def reset_password(database_url: str, username: str, password: str) -> None:
    username = security.normalize_username(username)
    error = security.validate_password(password, username)
    if error:
        raise SystemExit(error)
    factory = make_session_factory(make_engine(database_url))
    with session_scope(factory) as db:
        user = db.scalar(select(User).where(User.username == username))
        if user is None:
            raise SystemExit("المستخدم غير موجود")
        user.password_hash = security.hash_password(password)
        user.failed_attempts = 0
        user.locked_until = None
        user.is_active = True
        user.updated_at = utcnow()
        security.end_all_sessions(db, user.id)
        audit.log(
            db,
            AuditAction.PASSWORD_RESET,
            username="(سطر الأوامر)",
            entity_type="user",
            entity_id=user.id,
            details={"username": username},
        )


def main(argv: list[str] | None = None) -> int:
    use_utf8_console()
    parser = argparse.ArgumentParser(description="إدارة الحالات الميدانية")
    parser.add_argument("--config", type=Path, help="مسار config.ini")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check-db")
    sub.add_parser("init-db")
    p = sub.add_parser("create-admin")
    p.add_argument("--username", required=True)
    p.add_argument("--full-name", required=True)
    p = sub.add_parser("reset-password")
    p.add_argument("--username", required=True)
    args = parser.parse_args(argv)

    try:
        settings = load_settings(args.config)
    except ConfigError as e:
        print(e, file=sys.stderr)
        return 2

    if args.cmd == "check-db":
        try:
            with make_engine(settings.database_url).connect() as conn:
                conn.execute(text("SELECT 1"))
        except Exception as e:  # noqa: BLE001 — الرسالة لمدير النظام
            print(f"تعذر الاتصال بقاعدة البيانات: {e}", file=sys.stderr)
            return 1
        print("الاتصال بقاعدة البيانات سليم")
    elif args.cmd == "init-db":
        init_db(settings.database_url)
        print("الجداول جاهزة")
    elif args.cmd == "create-admin":
        create_admin(settings.database_url, args.username, args.full_name, _ask_password(args.username))
        print("أُنشئ مدير النظام")
    elif args.cmd == "reset-password":
        reset_password(settings.database_url, args.username, _ask_password(args.username))
        print("أُعيد تعيين كلمة المرور")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
