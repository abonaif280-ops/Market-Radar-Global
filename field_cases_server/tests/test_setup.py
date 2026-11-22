from __future__ import annotations

from fastapi.testclient import TestClient

from tests.conftest import form_token, login

LOCAL = ("127.0.0.1", 50000)
REMOTE = ("192.168.1.50", 50000)


def setup_data(page: str, **overrides):
    data = {
        "setup_csrf": form_token(page, "setup_csrf"),
        "username": "admin",
        "full_name": "مدير النظام",
        "password": "Madinah2026",
        "confirm_password": "Madinah2026",
    }
    data.update(overrides)
    return data


def test_first_run_opens_setup_in_the_browser(app):
    client = TestClient(app, client=LOCAL)
    response = client.get("/login", follow_redirects=False)
    assert response.headers["location"] == "/setup"
    page = client.get("/setup").text
    assert "أنشئ حساب" in page and "مثال صحيح" in page

    done = client.post("/setup", data=setup_data(page), follow_redirects=False)
    assert done.headers["location"] == "/login?msg=setup_done"
    assert login(client, "admin", "Madinah2026").status_code == 303

    # بعد وجود مستخدم: لا يمكن فتح الإعداد مرة أخرى.
    assert client.get("/setup", follow_redirects=False).headers["location"] == "/login"


def test_setup_explains_rejected_passwords(app):
    client = TestClient(app, client=LOCAL)
    page = client.get("/setup").text
    response = client.post("/setup", data=setup_data(page, password="admin12345", confirm_password="admin12345"))
    assert response.status_code == 400 and "اسم المستخدم" in response.text
    page = response.text
    response = client.post("/setup", data=setup_data(page, password="Madinah2026", confirm_password="Madinah2027"))
    assert "غير متطابقتين" in response.text
    # القيم المكتوبة تبقى.
    assert 'value="مدير النظام"' in response.text


def test_other_computers_cannot_create_the_admin(app):
    remote = TestClient(app, client=REMOTE)
    assert remote.get("/setup").status_code == 403
    response = remote.post(
        "/setup",
        data={"username": "x", "full_name": "x", "password": "Madinah2026", "confirm_password": "Madinah2026"},
    )
    assert response.status_code == 403
    local = TestClient(app, client=LOCAL)
    assert local.get("/setup").status_code == 200  # ما زال بلا مستخدمين


def test_setup_requires_its_form_token(app):
    client = TestClient(app, client=LOCAL)
    client.get("/setup")
    response = client.post(
        "/setup",
        data={"setup_csrf": "forged", "username": "admin", "full_name": "x",
              "password": "Madinah2026", "confirm_password": "Madinah2026"},
    )
    assert response.status_code == 400
