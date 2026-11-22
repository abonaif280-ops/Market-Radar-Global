from __future__ import annotations

import re

from sqlalchemy import select

from app.models import AuditLog
from tests.conftest import ADMIN_PASSWORD, form_token, logged_in, login


def _issued_password(html: str) -> str:
    match = re.search(r'<p class="secret" dir="ltr">([^<]+)</p>', html)
    assert match
    return match.group(1)


def _create(client, token, username="u117", role="entry"):
    return client.post(
        "/users/new",
        data={"csrf_token": token, "username": username, "full_name": "موظف إدخال", "role": role},
    )


def test_admin_creates_user_who_must_change_password(client, admin, db, app):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    response = _create(client, token)
    assert response.status_code == 200
    password = _issued_password(response.text)

    other = type(client)(app)
    first = login(other, "u117", password)
    assert first.headers["location"] == "/account/password"
    # لا يصل لأي صفحة قبل تغيير كلمة المرور.
    assert other.get("/", follow_redirects=False).headers["location"] == "/account/password"

    csrf = form_token(other.get("/account/password").text)
    other.post(
        "/account/password",
        data={
            "csrf_token": csrf,
            "current_password": password,
            "new_password": "Entry-User-Pass-1",
            "confirm_password": "Entry-User-Pass-1",
        },
    )
    assert other.get("/", follow_redirects=False).status_code == 200
    assert db.user("u117").must_change_password is False


def test_usernames_are_unique_and_validated(client, admin):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    _create(client, token)
    duplicate = _create(client, token, username="U117")
    assert duplicate.status_code == 400 and "مستخدم من قبل" in duplicate.text
    invalid = _create(client, token, username="مستخدم")
    assert invalid.status_code == 400


def test_non_admin_cannot_manage_users(client, admin, app):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    password = _issued_password(_create(client, token, role="supervisor").text)
    other = type(client)(app)
    login(other, "u117", password)
    csrf = form_token(other.get("/account/password").text)
    other.post(
        "/account/password",
        data={
            "csrf_token": csrf,
            "current_password": password,
            "new_password": "Supervisor-Pass-1",
            "confirm_password": "Supervisor-Pass-1",
        },
    )
    assert other.get("/users").status_code == 403
    assert "المستخدمون" not in other.get("/").text


def test_deactivating_a_user_ends_their_sessions(client, admin, db, app):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    password = _issued_password(_create(client, token).text)
    other = type(client)(app)
    login(other, "u117", password)
    user_id = db.user("u117").id

    client.post(
        f"/users/{user_id}",
        data={"csrf_token": token, "full_name": "موظف", "role": "entry"},
    )
    assert db.user("u117").is_active is False
    assert other.get("/account/password", follow_redirects=False).status_code == 303
    assert login(other, "u117", password).status_code == 401


def test_admin_cannot_lock_themselves_out(client, admin, db):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    admin_id = db.user(admin).id
    response = client.post(
        f"/users/{admin_id}",
        data={"csrf_token": token, "full_name": "مدير", "role": "entry", "is_active": "on"},
    )
    assert response.status_code == 400
    assert db.user(admin).role == "admin"


def test_reset_password_issues_new_temporary_password(client, admin, db):
    token = logged_in(client, admin, ADMIN_PASSWORD)
    first = _issued_password(_create(client, token).text)
    user_id = db.user("u117").id
    response = client.post(f"/users/{user_id}/reset-password", data={"csrf_token": token})
    second = _issued_password(response.text)
    assert first != second
    assert db.user("u117").must_change_password is True
    with db.scope() as s:
        actions = [a.action for a in s.scalars(select(AuditLog)).all()]
    assert "user_created" in actions and "password_reset" in actions
