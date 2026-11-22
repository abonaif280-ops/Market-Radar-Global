"""إنشاء الحالات وتعديلها وصياغة نصها — نفس قواعد تطبيق الجوال."""

from __future__ import annotations

import hashlib
import json
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import func, select, true
from sqlalchemy.orm import Session

from .. import audit
from ..clock import utcnow
from ..models import Attachment, Case, CaseParty, CaseStatus, CaseTypeField, LookupItem, TextTemplate, User
from ..seed_v1 import CASE_TYPE, CENTER, GENERIC_TEMPLATE_ID, GOVERNORATE, PARTY, REPORT_SOURCE
from . import formatting, template_engine

MAX_COUNT = 9999
MAX_TEXT = 4000
MAX_PHOTO_BYTES = 10 * 1024 * 1024
MAX_PHOTOS_PER_CASE = 30


class CaseAction:
    CREATED = "case_created"
    UPDATED = "case_updated"
    TEXT_EDITED = "case_text_edited"
    ATTACHMENT_ADDED = "attachment_added"
    ATTACHMENT_DELETED = "attachment_deleted"


# ------------------------------------------------------------------ القوائم


@dataclass(frozen=True)
class FieldDef:
    id: str
    case_type_id: str
    key: str
    label: str
    input_type: str
    options: list[str]
    is_required: bool

    @property
    def variable_key(self) -> str:
        """مفتاح الحقل في القالب: عنوانه مع استبدال المسافات بـ _."""
        return "_".join(self.label.split())

    @property
    def form_name(self) -> str:
        return f"xf__{self.id}"

    def is_empty(self, value: Any) -> bool:
        if value is None:
            return True
        if isinstance(value, str):
            return not value.strip()
        if isinstance(value, list):
            return not value
        return False  # "لا" إجابة صحيحة وليست فراغًا


@dataclass
class Choices:
    by_list: dict[str, list[LookupItem]]
    fields_by_type: dict[str, list[FieldDef]]
    labels: dict[str, str]
    sort_order: dict[str, int]

    def ids(self, list_key: str) -> set[str]:
        return {i.id for i in self.by_list.get(list_key, [])}


def load_choices(db: Session, include_ids: set[str] | None = None) -> Choices:
    """القوائم النشطة، مع أي عنصر معطّل مستخدم في حالة قائمة حتى لا يختفي من التعديل."""
    items = db.scalars(select(LookupItem).order_by(LookupItem.sort_order, LookupItem.label)).all()
    by_list: dict[str, list[LookupItem]] = {}
    for item in items:
        if item.is_active or (include_ids and item.id in include_ids):
            by_list.setdefault(item.list_key, []).append(item)
    fields_by_type: dict[str, list[FieldDef]] = {}
    for f in db.scalars(
        # == true() وليس is_(True): SQL Server لا يقبل "IS 1".
        select(CaseTypeField).where(CaseTypeField.is_active == true()).order_by(CaseTypeField.sort_order)
    ).all():
        fields_by_type.setdefault(f.case_type_id, []).append(
            FieldDef(
                id=f.id,
                case_type_id=f.case_type_id,
                key=f.field_key,
                label=f.label,
                input_type=f.input_type,
                options=json.loads(f.options) if f.options else [],
                is_required=f.is_required,
            )
        )
    return Choices(
        by_list=by_list,
        fields_by_type=fields_by_type,
        labels={i.id: i.label for i in items},
        sort_order={i.id: i.sort_order for i in items},
    )


# ------------------------------------------------------------------ النموذج


@dataclass
class CaseForm:
    case_type_id: str | None = None
    occurred_local: datetime | None = None  # بتوقيت الجهة، بدون منطقة زمنية
    governorate_id: str | None = None
    center_id: str | None = None
    location_text: str = ""
    report_source_id: str | None = None
    location_description: str = ""
    coordinates_text: str = ""
    case_info: str = ""
    action_taken: str = ""
    has_injuries: bool = False
    injuries_count: int = 0
    has_deaths: bool = False
    deaths_count: int = 0
    has_damage: bool = False
    damage_description: str = ""
    notes: str = ""
    party_ids: list[str] = field(default_factory=list)
    extra: dict[str, Any] = field(default_factory=dict)
    # أخطاء صيغة اكتُشفت أثناء قراءة النموذج (مثل رقم غير صالح).
    parse_errors: list[str] = field(default_factory=list)

    @property
    def coordinates(self) -> tuple[float, float] | None:
        return formatting.parse_coordinates(self.coordinates_text) if self.coordinates_text.strip() else None


def _text(form: Any, name: str, limit: int = MAX_TEXT) -> str:
    return str(form.get(name, "") or "").strip()[:limit]


def _int(value: str, errors: list[str], label: str) -> int:
    value = formatting.normalize_digits(value.strip())
    if not value:
        return 0
    try:
        return int(value)
    except ValueError:
        errors.append(f"{label}: أدخل رقمًا صحيحًا")
        return 0


def parse_form(form: Any, choices: Choices) -> CaseForm:
    errors: list[str] = []

    def lookup(name: str, list_key: str) -> str | None:
        value = _text(form, name, 80)
        return value if value in choices.ids(list_key) else None

    occurred = None
    raw_time = _text(form, "occurred_at", 20)
    if raw_time:
        try:
            occurred = datetime.fromisoformat(formatting.normalize_digits(raw_time)).replace(second=0, microsecond=0)
        except ValueError:
            errors.append("وقت البلاغ غير صحيح")

    data = CaseForm(
        case_type_id=lookup("case_type_id", CASE_TYPE),
        occurred_local=occurred,
        governorate_id=lookup("governorate_id", GOVERNORATE),
        center_id=lookup("center_id", CENTER),
        location_text=_text(form, "location_text", 500),
        report_source_id=lookup("report_source_id", REPORT_SOURCE),
        location_description=_text(form, "location_description"),
        coordinates_text=_text(form, "coordinates", 80),
        case_info=_text(form, "case_info"),
        action_taken=_text(form, "action_taken"),
        has_injuries=form.get("has_injuries") == "on",
        has_deaths=form.get("has_deaths") == "on",
        has_damage=form.get("has_damage") == "on",
        damage_description=_text(form, "damage_description"),
        notes=_text(form, "notes"),
        party_ids=[p for p in form.getlist("party_ids") if p in choices.ids(PARTY)],
        parse_errors=errors,
    )
    data.injuries_count = _int(str(form.get("injuries_count", "")), errors, "عدد الإصابات") if data.has_injuries else 0
    data.deaths_count = _int(str(form.get("deaths_count", "")), errors, "عدد الوفيات") if data.has_deaths else 0

    # المركز يجب أن يتبع المحافظة المختارة.
    if data.center_id:
        center = next((c for c in choices.by_list.get(CENTER, []) if c.id == data.center_id), None)
        if center and center.parent_id and center.parent_id != data.governorate_id:
            data.center_id = None

    for f in choices.fields_by_type.get(data.case_type_id or "", []):
        name = f.form_name
        if f.input_type == "boolean":
            data.extra[f.key] = form.get(name) == "on"
        elif f.input_type == "number":
            raw = formatting.normalize_digits(_text(form, name, 20))
            if raw:
                try:
                    number = float(raw)
                    data.extra[f.key] = int(number) if number.is_integer() else number
                except ValueError:
                    errors.append(f"{f.label}: أدخل رقمًا")
        elif f.input_type == "select":
            value = _text(form, name, 200)
            if value and value in f.options:
                data.extra[f.key] = value
        elif f.input_type == "multiSelect":
            values = [v for v in form.getlist(name) if v in f.options]
            if values:
                data.extra[f.key] = values
        else:
            value = _text(form, name)
            if value:
                data.extra[f.key] = value
    return data


def form_from_case(case: Case, party_ids: list[str], tz: ZoneInfo) -> CaseForm:
    lat, lng = case.latitude, case.longitude
    return CaseForm(
        case_type_id=case.case_type_id,
        occurred_local=to_local(case.occurred_at, tz),
        governorate_id=case.governorate_id,
        center_id=case.center_id,
        location_text=case.location_text or "",
        report_source_id=case.report_source_id,
        location_description=case.location_description or "",
        coordinates_text=formatting.format_coordinates(lat, lng) if lat is not None and lng is not None else "",
        case_info=case.case_info or "",
        action_taken=case.action_taken or "",
        has_injuries=case.has_injuries,
        injuries_count=case.injuries_count,
        has_deaths=case.has_deaths,
        deaths_count=case.deaths_count,
        has_damage=case.has_damage,
        damage_description=case.damage_description or "",
        notes=case.notes or "",
        party_ids=party_ids,
        extra=json.loads(case.extra_fields or "{}"),
    )


def to_local(utc_naive: datetime, tz: ZoneInfo) -> datetime:
    from datetime import timezone

    return utc_naive.replace(tzinfo=timezone.utc).astimezone(tz).replace(tzinfo=None)


def to_utc(local_naive: datetime, tz: ZoneInfo) -> datetime:
    from datetime import timezone

    return local_naive.replace(tzinfo=tz).astimezone(timezone.utc).replace(tzinfo=None)


# ------------------------------------------------------------------ التحقق


def validate(data: CaseForm, status: str, choices: Choices, now_local: datetime) -> list[str]:
    """المسودة تحتاج نوع الحالة فقط؛ المكتملة تحتاج الأساسيات (كما في الجوال)."""
    errors = list(data.parse_errors)
    if data.case_type_id is None:
        errors.append("اختر نوع الحالة")
    if data.occurred_local is None:
        errors.append("حدد وقت البلاغ")
    elif data.occurred_local > now_local + timedelta(minutes=5):
        errors.append("وقت البلاغ لا يمكن أن يكون في المستقبل")
    if data.has_injuries and not 1 <= data.injuries_count <= MAX_COUNT:
        errors.append("عدد الإصابات غير صحيح")
    if data.has_deaths and not 1 <= data.deaths_count <= MAX_COUNT:
        errors.append("عدد الوفيات غير صحيح")
    if data.coordinates_text.strip() and data.coordinates is None:
        errors.append("الإحداثيات غير صحيحة. مثال: 24.468245, 39.612354")
    if status == CaseStatus.DRAFT:
        return errors
    if data.governorate_id is None:
        errors.append("اختر المحافظة")
    if data.center_id is None and not data.location_text.strip():
        errors.append("حدد المركز أو اكتب الموقع")
    if data.report_source_id is None:
        errors.append("اختر مصدر البلاغ")
    for f in choices.fields_by_type.get(data.case_type_id or "", []):
        if f.is_required and f.is_empty(data.extra.get(f.key)):
            errors.append(f'أكمل حقل "{f.label}"')
    if data.has_damage and not data.damage_description.strip():
        errors.append("اكتب وصف الأضرار")
    return errors


# ------------------------------------------------------------------ الصياغة


def join_arabic(items: list[str]) -> str:
    return " و".join(items)


def location_phrase(location_text: str, center: str | None, governorate: str | None) -> str:
    if location_text:
        return location_text
    if center:
        return f"في {center}"
    if governorate:
        return f"بمحافظة {governorate}"
    return ""


_INJURY = ("إصابة واحدة", "إصابتان", "إصابات", "إصابة")
_DEATH = ("حالة وفاة واحدة", "حالتا وفاة", "حالات وفاة", "حالة وفاة")


def count_phrase(n: int, forms: tuple[str, str, str, str]) -> str:
    one, two, few, many = forms
    if n == 1:
        return one
    if n == 2:
        return two
    if n <= 10:
        return f"({n}) {few}"
    return f"({n}) {many}"


def casualties_phrase(injuries: int, deaths: int) -> str:
    if injuries <= 0 and deaths <= 0:
        return "دون تسجيل إصابات أو وفيات"
    parts = []
    if injuries > 0:
        parts.append(count_phrase(injuries, _INJURY))
    if deaths > 0:
        parts.append(count_phrase(deaths, _DEATH))
    return "ونتج عن ذلك " + " و".join(parts)


def template_variables(data: CaseForm, choices: Choices, photo_count: int) -> dict[str, Any]:
    label = choices.labels.get
    occurred = data.occurred_local
    location = data.location_text.strip()
    coords = data.coordinates
    parties = sorted(data.party_ids, key=lambda p: choices.sort_order.get(p, 0))
    injuries = data.injuries_count if data.has_injuries else 0
    deaths = data.deaths_count if data.has_deaths else 0
    variables: dict[str, Any] = {
        "الوقت": formatting.time_12(occurred) if occurred else "",
        "التاريخ": formatting.date(occurred) if occurred else "",
        "اليوم": formatting.weekday(occurred) if occurred else "",
        "نوع_الحالة": label(data.case_type_id or ""),
        "مصدر_البلاغ": label(data.report_source_id or ""),
        "المحافظة": label(data.governorate_id or ""),
        "المركز": label(data.center_id or ""),
        "الموقع": location,
        "عبارة_الموقع": location_phrase(
            location, label(data.center_id or ""), label(data.governorate_id or "")
        ),
        "وصف_الموقع": data.location_description.strip(),
        "الإحداثيات": formatting.format_coordinates(*coords) if coords else None,
        "معلومات_الحالة": data.case_info.strip(),
        "الإجراء_المتخذ": data.action_taken.strip(),
        "الجهات": join_arabic([label(p) or "" for p in parties]),
        "وجود_إصابات": data.has_injuries,
        "عدد_الإصابات": injuries,
        "وجود_وفيات": data.has_deaths,
        "عدد_الوفيات": deaths,
        "عبارة_الإصابات_والوفيات": casualties_phrase(injuries, deaths),
        "وجود_أضرار": data.has_damage,
        "وصف_الأضرار": data.damage_description.strip() if data.has_damage else "",
        "ملاحظات": data.notes.strip(),
        "عدد_الصور": photo_count,
    }
    for f in choices.fields_by_type.get(data.case_type_id or "", []):
        variables[f.variable_key] = data.extra.get(f.key)
    return variables


def template_for(db: Session, case_type_id: str | None) -> TextTemplate | None:
    if case_type_id:
        specific = db.scalars(
            select(TextTemplate)
            .where(TextTemplate.case_type_id == case_type_id, TextTemplate.is_active == true())
            .order_by(TextTemplate.is_default.desc())
        ).first()
        if specific:
            return specific
    return db.get(TextTemplate, GENERIC_TEMPLATE_ID)


def compose(db: Session, data: CaseForm, choices: Choices, photo_count: int) -> str:
    template = template_for(db, data.case_type_id)
    if template is None:
        return ""
    return template_engine.render(template.body, template_variables(data, choices, photo_count))


# ------------------------------------------------------------------ الصور


@dataclass
class Upload:
    filename: str
    content: bytes


class UploadError(Exception):
    pass


def detect_image(content: bytes) -> tuple[str, str] | None:
    """يحدد الصورة من محتواها لا من اسمها. يعيد (الامتداد، النوع)."""
    if content.startswith(b"\xff\xd8\xff"):
        return "jpg", "image/jpeg"
    if content.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png", "image/png"
    return None


def display_code_for(case_id: str, local: datetime) -> str:
    """EVT-YYYYMMDD-XXXXXX (نفس صيغة الجوال)."""
    return f"EVT-{local:%Y%m%d}-{case_id.replace('-', '')[:6].upper()}"


def _store_uploads(
    db: Session,
    data_dir: Path,
    case: Case,
    uploads: list[Upload],
    user: User,
    written: list[Path],
) -> int:
    if not uploads:
        return 0
    existing = db.scalar(
        select(func.count()).select_from(Attachment).where(
            Attachment.case_id == case.id, Attachment.deleted_at.is_(None)
        )
    )
    if existing + len(uploads) > MAX_PHOTOS_PER_CASE:
        raise UploadError(f"الحد الأقصى {MAX_PHOTOS_PER_CASE} صورة للحالة")
    seq = db.scalar(select(func.max(Attachment.seq)).where(Attachment.case_id == case.id)) or 0
    folder = data_dir / "attachments" / case.id
    folder.mkdir(parents=True, exist_ok=True)
    now = utcnow()
    for upload in uploads:
        if len(upload.content) > MAX_PHOTO_BYTES:
            raise UploadError(f"الصورة {upload.filename} أكبر من 10 ميجابايت")
        kind = detect_image(upload.content)
        if kind is None:
            raise UploadError(f"الملف {upload.filename} ليس صورة JPG أو PNG")
        ext, mime = kind
        seq += 1
        file_name = f"{case.display_code}_{seq:03d}.{ext}"
        target = folder / file_name
        tmp = target.with_suffix(".part")
        tmp.write_bytes(upload.content)
        tmp.replace(target)
        written.append(target)
        attachment = Attachment(
            id=str(uuid.uuid4()),
            case_id=case.id,
            seq=seq,
            file_name=file_name,
            relative_path=f"attachments/{case.id}/{file_name}",
            mime_type=mime,
            size_bytes=len(upload.content),
            sha256=hashlib.sha256(upload.content).hexdigest(),
            created_by=user.id,
            created_at=now,
        )
        db.add(attachment)
        audit.log(
            db, CaseAction.ATTACHMENT_ADDED, user=user, entity_type="case", entity_id=case.id,
            details={"file": file_name},
        )
    return len(uploads)


def active_photo_count(db: Session, case_id: str) -> int:
    return db.scalar(
        select(func.count()).select_from(Attachment).where(
            Attachment.case_id == case_id, Attachment.deleted_at.is_(None)
        )
    ) or 0


# ------------------------------------------------------------------ الحفظ


def _apply(case: Case, data: CaseForm, tz: ZoneInfo) -> None:
    coords = data.coordinates
    case.case_type_id = data.case_type_id  # type: ignore[assignment]
    case.occurred_at = to_utc(data.occurred_local, tz)  # type: ignore[arg-type]
    case.governorate_id = data.governorate_id
    case.center_id = data.center_id
    case.location_text = data.location_text or None
    case.report_source_id = data.report_source_id
    case.location_description = data.location_description or None
    case.latitude, case.longitude = coords if coords else (None, None)
    case.case_info = data.case_info or None
    case.action_taken = data.action_taken or None
    case.has_injuries = data.has_injuries
    case.injuries_count = data.injuries_count if data.has_injuries else 0
    case.has_deaths = data.has_deaths
    case.deaths_count = data.deaths_count if data.has_deaths else 0
    case.has_damage = data.has_damage
    case.damage_description = (data.damage_description or None) if data.has_damage else None
    case.notes = data.notes or None
    case.extra_fields = json.dumps(data.extra, ensure_ascii=False)


def _set_parties(db: Session, case_id: str, party_ids: list[str]) -> None:
    db.query(CaseParty).filter(CaseParty.case_id == case_id).delete(synchronize_session=False)
    for party_id in dict.fromkeys(party_ids):
        db.add(CaseParty(case_id=case_id, party_id=party_id))


def _refresh_text(db: Session, case: Case, data: CaseForm, choices: Choices) -> None:
    case.generated_text = compose(db, data, choices, active_photo_count(db, case.id))
    if not case.is_text_edited:
        case.final_text = case.generated_text


class StaleCase(Exception):
    """عُدّلت الحالة من مستخدم آخر بعد فتح النموذج."""


def create_case(
    db: Session,
    *,
    data: CaseForm,
    status: str,
    user: User,
    choices: Choices,
    tz: ZoneInfo,
    data_dir: Path,
    uploads: list[Upload],
    written: list[Path],
) -> Case:
    now = utcnow()
    case_id = str(uuid.uuid4())
    case = Case(
        id=case_id,
        display_code=display_code_for(case_id, to_local(now, tz)),
        status=status,
        revision=1,
        is_text_edited=False,
        created_by=user.id,
        updated_by=user.id,
        created_at=now,
        updated_at=now,
    )
    _apply(case, data, tz)
    db.add(case)
    db.flush()
    _set_parties(db, case.id, data.party_ids)
    _store_uploads(db, data_dir, case, uploads, user, written)
    db.flush()
    _refresh_text(db, case, data, choices)
    audit.log(
        db, CaseAction.CREATED, user=user, entity_type="case", entity_id=case.id,
        details={"display_code": case.display_code, "status": status},
    )
    return case


def update_case(
    db: Session,
    case: Case,
    *,
    data: CaseForm,
    status: str,
    expected_revision: int,
    user: User,
    choices: Choices,
    tz: ZoneInfo,
    data_dir: Path,
    uploads: list[Upload],
    remove_attachment_ids: list[str],
    written: list[Path],
) -> Case:
    if case.revision != expected_revision:
        raise StaleCase()
    _apply(case, data, tz)
    case.status = status
    _set_parties(db, case.id, data.party_ids)
    now = utcnow()
    if remove_attachment_ids:
        for attachment in db.scalars(
            select(Attachment).where(
                Attachment.case_id == case.id,
                Attachment.id.in_(remove_attachment_ids),
                Attachment.deleted_at.is_(None),
            )
        ).all():
            # حذف مرن: الملف يبقى حتى الحذف النهائي (ح3).
            attachment.deleted_at = now
            audit.log(
                db, CaseAction.ATTACHMENT_DELETED, user=user, entity_type="case", entity_id=case.id,
                details={"file": attachment.file_name},
            )
    _store_uploads(db, data_dir, case, uploads, user, written)
    db.flush()
    _refresh_text(db, case, data, choices)
    case.revision += 1
    case.updated_by = user.id
    case.updated_at = now
    audit.log(
        db, CaseAction.UPDATED, user=user, entity_type="case", entity_id=case.id,
        details={"display_code": case.display_code, "status": status, "revision": case.revision},
    )
    return case


def party_ids_of(db: Session, case_id: str) -> list[str]:
    return list(db.scalars(select(CaseParty.party_id).where(CaseParty.case_id == case_id)).all())
