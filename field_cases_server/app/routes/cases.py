"""إدخال الحالات وعرضها وتعديلها من المتصفح."""

from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import FileResponse
from sqlalchemy import select

from .. import audit
from ..cases import formatting, service
from ..cases.service import CaseAction, Choices, StaleCase, Upload, UploadError
from ..clock import utcnow
from ..models import Attachment, Case, CaseStatus, Role, User
from ..seed_v1 import CASE_TYPE, CENTER, GOVERNORATE, PARTY, REPORT_SOURCE
from ..web import check_csrf, client_ip, current_session, redirect, render, settings_of, tx

router = APIRouter(prefix="/cases")

# صور الحالة + هامش للحقول النصية.
MAX_REQUEST_BYTES = service.MAX_PHOTOS_PER_CASE * service.MAX_PHOTO_BYTES + 2 * 1024 * 1024

MESSAGES = {
    "created": "حُفظت الحالة",
    "updated": "حُفظت التعديلات",
    "text_saved": "حُفظ النص",
    "text_restored": "أُعيدت الصياغة الآلية",
}


def can_access(user: User, case: Case) -> bool:
    """مُدخل البيانات يرى ويعدّل حالاته فقط؛ المشرف ومدير النظام كل الحالات."""
    if case.deleted_at is not None:
        return False
    return user.role in (Role.ADMIN, Role.SUPERVISOR) or case.created_by == user.id


def _load(db, user: User, case_id: str) -> Case:
    case = db.get(Case, case_id)
    if case is None or not can_access(user, case):
        # نفس الاستجابة للحالة غير الموجودة وغير المسموحة (لا يُكشف وجودها).
        raise HTTPException(status_code=404)
    return case


def _form_context(choices: Choices, data: service.CaseForm, **extra) -> dict:
    return {
        "choices": choices,
        "lists": {
            "types": choices.by_list.get(CASE_TYPE, []),
            "governorates": choices.by_list.get(GOVERNORATE, []),
            "centers": choices.by_list.get(CENTER, []),
            "sources": choices.by_list.get(REPORT_SOURCE, []),
            "parties": choices.by_list.get(PARTY, []),
        },
        "form": data,
        "occurred_value": data.occurred_local.strftime("%Y-%m-%dT%H:%M") if data.occurred_local else "",
        **extra,
    }


async def _read_request(request: Request):
    length = request.headers.get("content-length")
    if length and length.isdigit() and int(length) > MAX_REQUEST_BYTES:
        raise HTTPException(status_code=413, detail="حجم الصور أكبر من المسموح")
    form = await request.form(max_files=service.MAX_PHOTOS_PER_CASE, max_fields=500)
    uploads: list[Upload] = []
    for item in form.getlist("photos"):
        filename = getattr(item, "filename", None)
        if not filename:
            continue
        content = await item.read(service.MAX_PHOTO_BYTES + 1)
        if content:
            uploads.append(Upload(filename=filename[:120], content=content))
    return form, uploads


def _status_from(form) -> str:
    return CaseStatus.DRAFT if form.get("action") == "draft" else CaseStatus.COMPLETED


def _cleanup(paths: list[Path]) -> None:
    for path in paths:
        path.unlink(missing_ok=True)


# ------------------------------------------------------------------ إنشاء


@router.get("/new")
def new_case_form(request: Request):
    settings = settings_of(request)
    with tx(request) as db:
        current_session(request, db)
        choices = service.load_choices(db)
    now_local = service.to_local(utcnow(), settings.tz)
    return render(
        request,
        "cases/form.html",
        _form_context(choices, service.CaseForm(occurred_local=now_local), case=None),
    )


@router.post("/new")
async def create_case(request: Request):
    settings = settings_of(request)
    form, uploads = await _read_request(request)
    status = _status_from(form)
    with tx(request) as db:
        active = current_session(request, db)
        check_csrf(active, form)
        choices = service.load_choices(db)
        data = service.parse_form(form, choices)
        errors = service.validate(data, status, choices, service.to_local(utcnow(), settings.tz))
    if errors:
        return render(
            request, "cases/form.html",
            _form_context(choices, data, case=None, errors=errors, photos_lost=bool(uploads)), 400,
        )
    written: list[Path] = []
    try:
        with tx(request) as db:
            user = current_session(request, db).user
            case = service.create_case(
                db, data=data, status=status, user=user, choices=choices, tz=settings.tz,
                data_dir=settings.data_dir, uploads=uploads, written=written,
            )
            case_id = case.id
    except UploadError as e:
        _cleanup(written)
        return render(
            request, "cases/form.html",
            _form_context(choices, data, case=None, errors=[str(e)], photos_lost=True), 400,
        )
    except Exception:
        _cleanup(written)
        raise
    return redirect(f"/cases/{case_id}?msg=created")


# ------------------------------------------------------------------ عرض


@router.get("/{case_id}")
def case_detail(request: Request, case_id: str):
    settings = settings_of(request)
    with tx(request) as db:
        active = current_session(request, db)
        case = _load(db, active.user, case_id)
        party_ids = service.party_ids_of(db, case.id)
        choices = service.load_choices(db, include_ids={
            case.case_type_id, case.governorate_id, case.center_id, case.report_source_id, *party_ids,
        } - {None})
        data = service.form_from_case(case, party_ids, settings.tz)
        photos = db.scalars(
            select(Attachment)
            .where(Attachment.case_id == case.id, Attachment.deleted_at.is_(None))
            .order_by(Attachment.seq)
        ).all()
        creator = db.get(User, case.created_by)
        updater = db.get(User, case.updated_by)
    fields = choices.fields_by_type.get(case.case_type_id, [])
    return render(
        request,
        "cases/detail.html",
        {
            "case": case,
            "data": data,
            "choices": choices,
            "fields": fields,
            "photos": photos,
            "creator": creator.full_name if creator else "",
            "updater": updater.full_name if updater else "",
            "occurred": formatting.date_time(data.occurred_local) if data.occurred_local else "",
            "created": formatting.date_time(service.to_local(case.created_at, settings.tz)),
            "updated": formatting.date_time(service.to_local(case.updated_at, settings.tz)),
            "status_label": CaseStatus.LABELS.get(case.status, case.status),
            "case_message": MESSAGES.get(request.query_params.get("msg", "")),
        },
    )


@router.get("/{case_id}/photos/{attachment_id}")
def photo(request: Request, case_id: str, attachment_id: str):
    settings = settings_of(request)
    with tx(request) as db:
        active = current_session(request, db)
        case = _load(db, active.user, case_id)
        attachment = db.get(Attachment, attachment_id)
        if attachment is None or attachment.case_id != case.id or attachment.deleted_at is not None:
            raise HTTPException(status_code=404)
        relative, mime, name = attachment.relative_path, attachment.mime_type, attachment.file_name
    root = settings.data_dir.resolve()
    path = (root / relative).resolve()
    if not path.is_relative_to(root) or not path.is_file():
        raise HTTPException(status_code=404)
    return FileResponse(
        path, media_type=mime, filename=name, content_disposition_type="inline",
        headers={"Cache-Control": "private, max-age=3600"},
    )


# ------------------------------------------------------------------ تعديل


@router.get("/{case_id}/edit")
def edit_case_form(request: Request, case_id: str):
    settings = settings_of(request)
    with tx(request) as db:
        active = current_session(request, db)
        case = _load(db, active.user, case_id)
        party_ids = service.party_ids_of(db, case.id)
        choices = service.load_choices(db, include_ids={
            case.case_type_id, case.governorate_id, case.center_id, case.report_source_id, *party_ids,
        } - {None})
        data = service.form_from_case(case, party_ids, settings.tz)
        photos = db.scalars(
            select(Attachment)
            .where(Attachment.case_id == case.id, Attachment.deleted_at.is_(None))
            .order_by(Attachment.seq)
        ).all()
    return render(request, "cases/form.html", _form_context(choices, data, case=case, photos=photos))


@router.post("/{case_id}/edit")
async def update_case(request: Request, case_id: str):
    settings = settings_of(request)
    form, uploads = await _read_request(request)
    status = _status_from(form)
    try:
        expected_revision = int(str(form.get("revision", "0")))
    except ValueError:
        expected_revision = -1
    remove_ids = [str(v) for v in form.getlist("remove_photo")][: service.MAX_PHOTOS_PER_CASE]

    with tx(request) as db:
        active = current_session(request, db)
        check_csrf(active, form)
        case = _load(db, active.user, case_id)
        choices = service.load_choices(db, include_ids={
            case.case_type_id, case.governorate_id, case.center_id, case.report_source_id,
        } - {None})
        data = service.parse_form(form, choices)
        errors = service.validate(data, status, choices, service.to_local(utcnow(), settings.tz))
        photos = db.scalars(
            select(Attachment)
            .where(Attachment.case_id == case.id, Attachment.deleted_at.is_(None))
            .order_by(Attachment.seq)
        ).all()
    if errors:
        return render(
            request, "cases/form.html",
            _form_context(choices, data, case=case, photos=photos, errors=errors, photos_lost=bool(uploads)),
            400,
        )
    written: list[Path] = []
    try:
        with tx(request) as db:
            active = current_session(request, db)
            # نسخة جديدة داخل هذه الـ Transaction؛ `case` من القراءة الأولى يبقى صالحًا
            # لإعادة عرض النموذج إن أُلغيت هذه الـ Transaction.
            fresh = _load(db, active.user, case_id)
            service.update_case(
                db, fresh, data=data, status=status, expected_revision=expected_revision,
                user=active.user, choices=choices, tz=settings.tz, data_dir=settings.data_dir,
                uploads=uploads, remove_attachment_ids=remove_ids, written=written,
            )
    except StaleCase:
        _cleanup(written)
        return render(
            request, "cases/form.html",
            _form_context(
                choices, data, case=case, photos=photos, photos_lost=bool(uploads),
                errors=["عدّل مستخدم آخر هذه الحالة بعد فتحك لها. افتحها من جديد ثم أعد التعديل."],
            ),
            409,
        )
    except UploadError as e:
        _cleanup(written)
        return render(
            request, "cases/form.html",
            _form_context(choices, data, case=case, photos=photos, errors=[str(e)], photos_lost=True),
            400,
        )
    except Exception:
        _cleanup(written)
        raise
    return redirect(f"/cases/{case_id}?msg=updated")


@router.post("/{case_id}/text")
async def save_text(request: Request, case_id: str):
    form = await request.form()
    with tx(request) as db:
        active = current_session(request, db)
        check_csrf(active, form)
        case = _load(db, active.user, case_id)
        if str(form.get("revision", "")) != str(case.revision):
            return redirect(f"/cases/{case_id}")
        if form.get("action") == "restore":
            case.is_text_edited = False
            case.final_text = case.generated_text
            message = "text_restored"
        else:
            text = str(form.get("final_text", "")).strip()[: service.MAX_TEXT * 2]
            case.final_text = text or case.generated_text
            case.is_text_edited = bool(text) and text != (case.generated_text or "")
            message = "text_saved"
        case.revision += 1
        case.updated_by = active.user.id
        case.updated_at = utcnow()
        audit.log(
            db, CaseAction.TEXT_EDITED, user=active.user, entity_type="case", entity_id=case.id,
            details={"display_code": case.display_code, "restored": message == "text_restored"},
            ip=client_ip(request),
        )
    return redirect(f"/cases/{case_id}?msg={message}")
