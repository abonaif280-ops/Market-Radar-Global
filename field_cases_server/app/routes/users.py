"""إدارة المستخدمين (مدير النظام فقط)."""

from __future__ import annotations

import secrets
import string

from fastapi import APIRouter, HTTPException, Request
from sqlalchemy import select

from .. import audit, security
from ..audit import AuditAction
from ..clock import utcnow
from ..models import Role, User
from ..web import check_csrf, client_ip, current_session, redirect, render, tx

router = APIRouter(prefix="/users")

ADMIN_ONLY = (Role.ADMIN,)


def temporary_password() -> str:
    """كلمة مرور مؤقتة تُعرض مرة واحدة؛ يُلزم المستخدم بتغييرها عند أول دخول."""
    alphabet = "".join(c for c in string.ascii_letters + string.digits if c not in "0O1lI")
    while True:
        value = "".join(secrets.choice(alphabet) for _ in range(12))
        if security.validate_password(value) is None:
            return value


@router.get("")
def list_users(request: Request):
    with tx(request) as db:
        current_session(request, db, roles=ADMIN_ONLY)
        users = db.scalars(select(User).order_by(User.full_name)).all()
    return render(request, "users/list.html", {"users": users, "now": utcnow()})


@router.get("/new")
def new_user_form(request: Request):
    with tx(request) as db:
        current_session(request, db, roles=ADMIN_ONLY)
    return render(request, "users/form.html", {"edit": None, "values": {"role": Role.ENTRY}})


@router.post("/new")
async def create_user(request: Request):
    form = await request.form()
    with tx(request) as db:
        active = current_session(request, db, roles=ADMIN_ONLY)
        check_csrf(active, form)
        values = {
            "username": security.normalize_username(str(form.get("username", ""))),
            "full_name": str(form.get("full_name", "")).strip()[:200],
            "role": str(form.get("role", "")),
        }
        error = (
            security.validate_username(values["username"])
            or ("الاسم الكامل مطلوب" if not values["full_name"] else None)
            or ("الدور غير صالح" if values["role"] not in Role.ALL else None)
        )
        if error is None and db.scalar(select(User).where(User.username == values["username"])):
            error = "اسم المستخدم مستخدم من قبل"
        if error:
            return render(
                request, "users/form.html", {"edit": None, "values": values, "error": error}, 400
            )
        password = temporary_password()
        now = utcnow()
        user = User(
            username=values["username"],
            full_name=values["full_name"],
            role=values["role"],
            password_hash=security.hash_password(password),
            is_active=True,
            must_change_password=True,
            failed_attempts=0,
            created_at=now,
            updated_at=now,
        )
        db.add(user)
        db.flush()
        audit.log(
            db,
            AuditAction.USER_CREATED,
            user=active.user,
            entity_type="user",
            entity_id=user.id,
            details={"username": user.username, "role": user.role},
            ip=client_ip(request),
        )
    return render(request, "users/password_issued.html", {"target": user, "password": password})


def _load(db, user_id: int) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404)
    return user


@router.get("/{user_id}")
def edit_user_form(request: Request, user_id: int):
    with tx(request) as db:
        current_session(request, db, roles=ADMIN_ONLY)
        user = _load(db, user_id)
    return render(
        request,
        "users/form.html",
        {
            "edit": user,
            "values": {"full_name": user.full_name, "role": user.role, "is_active": user.is_active},
            "now": utcnow(),
        },
    )


@router.post("/{user_id}")
async def update_user(request: Request, user_id: int):
    form = await request.form()
    with tx(request) as db:
        active = current_session(request, db, roles=ADMIN_ONLY)
        check_csrf(active, form)
        user = _load(db, user_id)
        values = {
            "full_name": str(form.get("full_name", "")).strip()[:200],
            "role": str(form.get("role", "")),
            "is_active": form.get("is_active") == "on",
        }
        error = ("الاسم الكامل مطلوب" if not values["full_name"] else None) or (
            "الدور غير صالح" if values["role"] not in Role.ALL else None
        )
        # لا يُسمح لمدير النظام بإيقاف نفسه أو إزالة صلاحيته (حتى لا يبقى النظام بلا مدير).
        if error is None and user.id == active.user.id and (
            not values["is_active"] or values["role"] != Role.ADMIN
        ):
            error = "لا يمكنك إيقاف حسابك أو تغيير دورك"
        if error:
            return render(
                request,
                "users/form.html",
                {"edit": user, "values": values, "error": error, "now": utcnow()},
                400,
            )
        changes = {
            k: v for k, v in values.items() if getattr(user, k) != v
        }
        for key, value in values.items():
            setattr(user, key, value)
        user.updated_at = utcnow()
        if not user.is_active:
            security.end_all_sessions(db, user.id)
        if changes:
            audit.log(
                db,
                AuditAction.USER_UPDATED,
                user=active.user,
                entity_type="user",
                entity_id=user.id,
                details={"username": user.username, **changes},
                ip=client_ip(request),
            )
    return redirect("/users?msg=user_updated")


@router.post("/{user_id}/reset-password")
async def reset_password(request: Request, user_id: int):
    form = await request.form()
    with tx(request) as db:
        active = current_session(request, db, roles=ADMIN_ONLY)
        check_csrf(active, form)
        user = _load(db, user_id)
        password = temporary_password()
        user.password_hash = security.hash_password(password)
        user.must_change_password = True
        user.failed_attempts = 0
        user.locked_until = None
        user.updated_at = utcnow()
        security.end_all_sessions(db, user.id)
        audit.log(
            db,
            AuditAction.PASSWORD_RESET,
            user=active.user,
            entity_type="user",
            entity_id=user.id,
            details={"username": user.username},
            ip=client_ip(request),
        )
    return render(request, "users/password_issued.html", {"target": user, "password": password})


@router.post("/{user_id}/unlock")
async def unlock(request: Request, user_id: int):
    form = await request.form()
    with tx(request) as db:
        active = current_session(request, db, roles=ADMIN_ONLY)
        check_csrf(active, form)
        user = _load(db, user_id)
        user.locked_until = None
        user.failed_attempts = 0
        user.updated_at = utcnow()
        audit.log(
            db,
            AuditAction.USER_UPDATED,
            user=active.user,
            entity_type="user",
            entity_id=user.id,
            details={"username": user.username, "unlocked": True},
            ip=client_ip(request),
        )
    return redirect("/users?msg=user_unlocked")
