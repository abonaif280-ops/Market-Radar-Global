from __future__ import annotations

import re
from datetime import datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.models import Attachment, AuditLog, Case, CaseParty
from tests.conftest import form_token, logged_in, make_user

JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 200
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 200


def entry_client(app, username="u117"):
    password = make_user(app, username, "entry")
    client = TestClient(app)
    token = logged_in(client, username, password)
    return client, token


def base_form(token, **overrides):
    data = {
        "csrf_token": token,
        "case_type_id": "case_type:SOLID_OBJECT",
        "occurred_at": "2026-01-10T19:30",
        "report_source_id": "report_source:911",
        "governorate_id": "governorate:BADR",
        "center_id": "center:RAYES",
        "location_text": "جنوب مركز الرايس",
        "xf__field:SOLID_OBJECT:object_state": "أجزاء من جسم صلب",
        "xf__field:SOLID_OBJECT:has_fire": "on",
        "party_ids": ["party:EOD", "party:CIVIL_DEF"],
        "action": "complete",
    }
    data.update(overrides)
    return data


def case_id_from(response) -> str:
    match = re.search(r"/cases/([0-9a-f-]{36})", response.headers["location"])
    assert match, response.text
    return match.group(1)


def test_entry_user_creates_a_case_with_photos(app, db):
    client, token = entry_client(app)
    response = client.post(
        "/cases/new",
        data=base_form(token),
        files=[("photos", ("a.jpg", JPEG, "image/jpeg")), ("photos", ("b.png", PNG, "image/png"))],
        follow_redirects=False,
    )
    assert response.status_code == 303, response.text
    case_id = case_id_from(response)

    page = client.get(f"/cases/{case_id}").text
    assert "عند الساعة 7:30 مساءً ورد بلاغ من العمليات الموحدة (911)" in page
    assert "وجرى إبلاغ الدفاع المدني وإدارة الأسلحة والمتفجرات" in page

    with db.scope() as s:
        case = s.get(Case, case_id)
        assert case.status == "completed" and case.revision == 1
        assert re.fullmatch(r"EVT-\d{8}-[0-9A-F]{6}", case.display_code)
        # 19:30 بتوقيت الرياض = 16:30 UTC
        assert case.occurred_at == datetime(2026, 1, 10, 16, 30)
        photos = s.scalars(select(Attachment).where(Attachment.case_id == case_id).order_by(Attachment.seq)).all()
        assert [p.file_name for p in photos] == [f"{case.display_code}_001.jpg", f"{case.display_code}_002.png"]
        assert len(s.scalars(select(CaseParty).where(CaseParty.case_id == case_id)).all()) == 2
        photo_id = photos[0].id
        actions = [a.action for a in s.scalars(select(AuditLog)).all()]
    assert "case_created" in actions and actions.count("attachment_added") == 2

    served = client.get(f"/cases/{case_id}/photos/{photo_id}")
    assert served.status_code == 200 and served.content == JPEG
    assert served.headers["content-type"] == "image/jpeg"
    assert "مرحبًا" in client.get("/").text and case_id in client.get("/").text


def test_completed_case_needs_basics_but_draft_does_not(app):
    client, token = entry_client(app)
    missing = base_form(token, governorate_id="", center_id="", location_text="", report_source_id="")
    response = client.post("/cases/new", data=missing)
    assert response.status_code == 400
    for message in ("اختر المحافظة", "حدد المركز أو اكتب الموقع", "اختر مصدر البلاغ"):
        assert message in response.text
    # القيم المدخلة تبقى في النموذج.
    assert "أجزاء من جسم صلب" in response.text

    draft = client.post("/cases/new", data={**missing, "action": "draft"}, follow_redirects=False)
    assert draft.status_code == 303
    assert "مسودة" in client.get(draft.headers["location"]).text


def test_future_time_and_bad_counts_rejected(app):
    client, token = entry_client(app)
    future = (datetime.now() + timedelta(days=2)).strftime("%Y-%m-%dT%H:%M")
    response = client.post(
        "/cases/new",
        data=base_form(token, occurred_at=future, has_injuries="on", injuries_count="abc", coordinates="999, 1"),
    )
    assert response.status_code == 400
    assert "في المستقبل" in response.text
    assert "عدد الإصابات" in response.text
    assert "الإحداثيات غير صحيحة" in response.text


def test_non_image_upload_is_rejected_and_nothing_is_saved(app, db, settings):
    client, token = entry_client(app)
    response = client.post(
        "/cases/new",
        data=base_form(token),
        files=[("photos", ("a.jpg", JPEG, "image/jpeg")), ("photos", ("evil.jpg", b"MZ\x90\x00 not an image", "image/jpeg"))],
    )
    assert response.status_code == 400
    assert "ليس صورة" in response.text
    with db.scope() as s:
        assert s.scalars(select(Case)).all() == []
    folder = settings.data_dir / "attachments"
    assert not folder.exists() or not any(p.is_file() for p in folder.rglob("*"))


def test_entry_users_see_only_their_own_cases(app):
    owner, token = entry_client(app, "u1")
    case_id = case_id_from(owner.post("/cases/new", data=base_form(token), follow_redirects=False))

    other, _ = entry_client(app, "u2")
    assert other.get(f"/cases/{case_id}").status_code == 404
    assert other.get(f"/cases/{case_id}/edit").status_code == 404
    assert case_id not in other.get("/").text

    password = make_user(app, "sup", "supervisor")
    supervisor = TestClient(app)
    logged_in(supervisor, "sup", password)
    assert supervisor.get(f"/cases/{case_id}").status_code == 200
    assert case_id in supervisor.get("/").text


def test_edit_regenerates_text_and_detects_conflicts(app, db):
    client, token = entry_client(app)
    case_id = case_id_from(
        client.post(
            "/cases/new", data=base_form(token),
            files=[("photos", ("a.jpg", JPEG, "image/jpeg"))], follow_redirects=False,
        )
    )
    with db.scope() as s:
        photo_id = s.scalars(select(Attachment.id).where(Attachment.case_id == case_id)).one()

    edit_page = client.get(f"/cases/{case_id}/edit").text
    assert 'name="revision" value="1"' in edit_page and "أجزاء من جسم صلب" in edit_page
    response = client.post(
        f"/cases/{case_id}/edit",
        data=base_form(token, revision="1", has_injuries="on", injuries_count="2", remove_photo=photo_id),
        follow_redirects=False,
    )
    assert response.status_code == 303
    with db.scope() as s:
        case = s.get(Case, case_id)
        assert case.revision == 2 and "إصابتان" in case.final_text
        assert s.get(Attachment, photo_id).deleted_at is not None

    # نموذج قديم (الإصدار 1) بعد أن أصبحت الحالة 2: يُرفض ولا يمسح التعديل.
    stale = client.post(f"/cases/{case_id}/edit", data=base_form(token, revision="1"))
    assert stale.status_code == 409 and "مستخدم آخر" in stale.text
    with db.scope() as s:
        assert s.get(Case, case_id).injuries_count == 2


def test_manual_text_survives_edits_until_restored(app, db):
    client, token = entry_client(app)
    case_id = case_id_from(client.post("/cases/new", data=base_form(token), follow_redirects=False))
    client.post(f"/cases/{case_id}/text", data={"csrf_token": token, "revision": "1", "final_text": "نص يدوي", "action": "save"})
    client.post(f"/cases/{case_id}/edit", data=base_form(token, revision="2", notes="ملاحظة"))
    with db.scope() as s:
        case = s.get(Case, case_id)
        assert case.final_text == "نص يدوي" and case.is_text_edited
        revision = case.revision
    client.post(f"/cases/{case_id}/text", data={"csrf_token": token, "revision": str(revision), "action": "restore"})
    with db.scope() as s:
        case = s.get(Case, case_id)
        assert not case.is_text_edited and case.final_text == case.generated_text


def test_center_must_belong_to_selected_governorate(app, db):
    client, token = entry_client(app)
    case_id = case_id_from(
        client.post("/cases/new", data=base_form(token, governorate_id="governorate:YNB"), follow_redirects=False)
    )
    with db.scope() as s:
        assert s.get(Case, case_id).center_id is None


def test_case_forms_require_csrf(app):
    client, token = entry_client(app)
    data = base_form(token)
    data.pop("csrf_token")
    assert client.post("/cases/new", data=data).status_code == 400


def test_new_case_page_renders_all_lists(app):
    client, _ = entry_client(app)
    page = client.get("/cases/new").text
    for label in ("جسم صلب", "طائرة مسيرة", "العمليات الموحدة (911)", "مركز الرايس", "الهلال الأحمر", "حالة الجسم"):
        assert label in page
    assert form_token(page)
