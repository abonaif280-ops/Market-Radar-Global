"""كل اختبار يبدأ بقاعدة فارغة مُنشأة بالـ Migrations نفسها التي تُستخدم في التثبيت.

قاعدة الاختبار من FC_TEST_DATABASE_URL (PostgreSQL أو SQL Server في CI)،
وإلا ملف SQLite مؤقت.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import MetaData, select

from app.config import Settings
from app.db import make_engine, make_session_factory, session_scope
from app.main import create_app
from app.models import User
from manage import create_admin, init_db

ADMIN_PASSWORD = "Strong-Pass-2026"


@pytest.fixture
def database_url(tmp_path: Path) -> str:
    url = os.environ.get("FC_TEST_DATABASE_URL") or f"sqlite:///{tmp_path / 'test.db'}"
    engine = make_engine(url)
    meta = MetaData()
    meta.reflect(bind=engine)
    meta.drop_all(bind=engine)
    engine.dispose()
    init_db(url)
    return url


@pytest.fixture
def settings(database_url: str, tmp_path: Path) -> Settings:
    return Settings(
        host="127.0.0.1",
        port=8080,
        database_url=database_url,
        tls_cert_file=None,
        tls_key_file=None,
        session_idle_minutes=30,
        session_max_hours=12,
        max_login_attempts=5,
        lockout_minutes=15,
        data_dir=tmp_path / "data",
    )


@pytest.fixture
def app(settings: Settings):
    application = create_app(settings)
    yield application
    application.state.engine.dispose()


@pytest.fixture
def client(app) -> TestClient:
    return TestClient(app)


@pytest.fixture
def db(app):
    factory = app.state.session_factory

    class Helper:
        def scope(self):
            return session_scope(factory)

        def user(self, username: str) -> User:
            with session_scope(factory) as s:
                return s.scalar(select(User).where(User.username == username))

    return Helper()


@pytest.fixture
def admin(settings: Settings) -> str:
    create_admin(settings.database_url, "admin", "مدير النظام", ADMIN_PASSWORD)
    return "admin"


def form_token(html: str, name: str = "csrf_token") -> str:
    match = re.search(rf'name="{name}" value="([^"]+)"', html)
    assert match, f"{name} not found"
    return match.group(1)


def login(client: TestClient, username: str, password: str):
    page = client.get("/login")
    return client.post(
        "/login",
        data={
            "username": username,
            "password": password,
            "login_csrf": form_token(page.text, "login_csrf"),
        },
        follow_redirects=False,
    )


def logged_in(client: TestClient, username: str, password: str) -> str:
    """يدخل ويعيد رمز CSRF للجلسة."""
    response = login(client, username, password)
    assert response.status_code == 303, response.text
    page = client.get("/account/password")
    return form_token(page.text)
