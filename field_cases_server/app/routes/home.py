from __future__ import annotations

from fastapi import APIRouter, Request
from sqlalchemy import select

from ..cases import formatting, service
from ..models import Case, CaseStatus, LookupItem, Role
from ..web import current_session, render, settings_of, tx

router = APIRouter()


@router.get("/")
def home(request: Request):
    settings = settings_of(request)
    with tx(request) as db:
        active = current_session(request, db)
        user = active.user
        query = select(Case, LookupItem.label).join(LookupItem, LookupItem.id == Case.case_type_id).where(
            Case.deleted_at.is_(None)
        )
        if user.role not in (Role.ADMIN, Role.SUPERVISOR):
            query = query.where(Case.created_by == user.id)
        rows = db.execute(query.order_by(Case.updated_at.desc()).limit(10)).all()
        recent = [
            {
                "id": case.id,
                "code": case.display_code,
                "type": type_label,
                "status": CaseStatus.LABELS.get(case.status, case.status),
                "draft": case.status == CaseStatus.DRAFT,
                "occurred": formatting.date_time(service.to_local(case.occurred_at, settings.tz)),
            }
            for case, type_label in rows
        ]
        sees_all = user.role in (Role.ADMIN, Role.SUPERVISOR)
    return render(request, "home.html", {"recent": recent, "sees_all": sees_all})
