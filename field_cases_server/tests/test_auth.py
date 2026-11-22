from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select

from app.clock import utcnow
from app.models import AuditLog, UserSession
from tests.conftest import ADMIN_PASSWORD, form_token, logged_in, login


def test_pages_require_login(client):
    for path in ("/", "/users", "/account/password"):
        response = client.get(path, follow_redirects=False)
        assert response.status_code == 303
        assert response.headers["location"] == "/login"


def test_login_success_sets_a_protected_cookie(client, admin):
    response = login(client, admin, ADMIN_PASSWORD)
    assert response.status_code == 303
    assert response.headers["location"] == "/"
    cookie = response.headers["set-cookie"]
    assert "fc_session=" in cookie
    assert "HttpOnly" in cookie and "SameSite=strict" in cookie
    assert "مرحبًا" in client.get("/").text


def test_wrong_password_and_unknown_user_get_the_same_message(client, admin):
    wrong = login(client, admin, "Wrong-Pass-123")
    unknown = login(client, "nobody", "Wrong-Pass-123")
    assert wrong.status_code == unknown.status_code == 401
    message = "اسم المستخدم أو كلمة المرور غير صحيحة"
    assert message in wrong.text and message in unknown.text


def test_account_locks_after_repeated_failures(client, admin, db):
    for _ in range(5):
        login(client, admin, "Wrong-Pass-123")
    # حتى كلمة المرور الصحيحة مرفوضة أثناء القفل.
    response = login(client, admin, ADMIN_PASSWORD)
    assert response.status_code == 401
    assert "مقفل مؤقتًا" in response.text
    with db.scope() as s:
        actions = [a.action for a in s.scalars(select(AuditLog)).all()]
    assert actions.count("login_failed") == 4
    assert "login_locked" in actions


def test_login_requires_the_login_form_token(client, admin):
    response = client.post(
        "/login",
        data={"username": admin, "password": ADMIN_PASSWORD, "login_csrf": "forged"},
        follow_redirects=False,
    )
    assert response.status_code == 400


def test_forms_without_csrf_token_are_rejected(client, admin):
    logged_in(client, admin, ADMIN_PASSWORD)
    response = client.post(
        "/account/password",
        data={"current_password": ADMIN_PASSWORD, "new_password": "x", "confirm_password": "x"},
    )
    assert response.status_code == 400
    assert "انتهت صلاحية النموذج" in response.text


def test_idle_session_expires(client, admin, db):
    logged_in(client, admin, ADMIN_PASSWORD)
    with db.scope() as s:
        for record in s.scalars(select(UserSession)).all():
            record.last_seen_at = utcnow() - timedelta(minutes=31)
    response = client.get("/", follow_redirects=False)
    assert response.headers["location"] == "/login"


def test_logout_ends_the_session(client, admin, db):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    client.post("/logout", data={"csrf_token": token})
    assert client.get("/", follow_redirects=False).status_code == 303
    with db.scope() as s:
        assert s.scalars(select(UserSession)).all() == []


def test_change_password(client, admin, db):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    bad = client.post(
        "/account/password",
        data={
            "csrf_token": token,
            "current_password": ADMIN_PASSWORD,
            "new_password": "short1",
            "confirm_password": "short1",
        },
    )
    assert bad.status_code == 400
    ok = client.post(
        "/account/password",
        data={
            "csrf_token": token,
            "current_password": ADMIN_PASSWORD,
            "new_password": "New-Strong-Pass-99",
            "confirm_password": "New-Strong-Pass-99",
        },
        follow_redirects=False,
    )
    assert ok.status_code == 303
    stored = db.user(admin).password_hash
    assert stored.startswith("$argon2id$")
    assert "New-Strong-Pass-99" not in stored


def test_security_headers_block_external_resources(client):
    response = client.get("/login")
    csp = response.headers["content-security-policy"]
    assert "default-src 'self'" in csp and "frame-ancestors 'none'" in csp
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["cache-control"] == "no-store"


def test_health_reports_database(client):
    assert client.get("/health").json()["status"] == "ok"


def test_no_api_docs_exposed(client):
    for path in ("/docs", "/redoc", "/openapi.json"):
        assert client.get(path).status_code == 404


def test_login_page_csrf_token_rendered(client):
    assert form_token(client.get("/login").text, "login_csrf")
