"""أول تشغيل: إنشاء حساب مدير النظام من المتصفح بدل نافذة الأوامر.

نافذة الأوامر في Windows لا تعرض العربية بشكل صحيح، فالإعداد هنا بصفحة عربية.
الحماية: الصفحة متاحة فقط إذا لم يوجد أي مستخدم، وفقط من السيرفر نفسه
(127.0.0.1)؛ لا يستطيع جهاز آخر في الشبكة إنشاء المدير.
"""

from __future__ import annotations

import secrets

from fastapi import APIRouter, Request
from sqlalchemy import func, select

from .. import audit, security
from ..audit import AuditAction
from ..clock import utcnow
from ..models import Role, User
from ..web import LOGIN_CSRF_COOKIE, client_ip, redirect, render, settings_of, tx

router = APIRouter()

LOOPBACK = {"127.0.0.1", "::1", "localhost"}


def has_users(request: Request) -> bool:
    with tx(request) as db:
        return (db.scalar(select(func.count()).select_from(User)) or 0) > 0


def is_local(request: Request) -> bool:
    return client_ip(request) in LOOPBACK


def _page(request: Request, values: dict, error: str | None = None, status: int = 200):
    token = secrets.token_urlsafe(32)
    response = render(
        request,
        "setup.html",
        {"values": values, "error": error, "setup_csrf": token, "min_length": security.MIN_PASSWORD_LENGTH},
        status_code=status,
    )
    response.set_cookie(
        LOGIN_CSRF_COOKIE, token, httponly=True, samesite="strict",
        secure=settings_of(request).https, max_age=1800,
    )
    return response


def _not_here(request: Request):
    return render(
        request,
        "error.html",
        {
            "title": "لم يُجهَّز البرنامج بعد",
            "detail": "افتح البرنامج على السيرفر نفسه (http://127.0.0.1:8080) لإنشاء حساب مدير النظام أول مرة.",
        },
        status_code=403,
    )


@router.get("/setup")
def setup_form(request: Request):
    if has_users(request):
        return redirect("/login")
    if not is_local(request):
        return _not_here(request)
    return _page(request, {"username": "admin", "full_name": ""})


@router.post("/setup")
async def setup(request: Request):
    if has_users(request):
        return redirect("/login")
    if not is_local(request):
        return _not_here(request)
    form = await request.form()
    values = {
        "username": security.normalize_username(str(form.get("username", "")))[:64],
        "full_name": str(form.get("full_name", "")).strip()[:200],
    }
    if not security.csrf_matches(request.cookies.get(LOGIN_CSRF_COOKIE), str(form.get("setup_csrf", ""))):
        return _page(request, values, "انتهت صلاحية الصفحة، حاول مرة أخرى", 400)
    password = str(form.get("password", ""))[:256]
    confirm = str(form.get("confirm_password", ""))[:256]
    error = (
        security.validate_username(values["username"])
        or ("اكتب الاسم الكامل" if not values["full_name"] else None)
        or security.validate_password(password, values["username"])
        or ("كلمتا المرور غير متطابقتين" if password != confirm else None)
    )
    if error:
        return _page(request, values, error, 400)
    with tx(request) as db:
        # تحقق مرة أخرى داخل الـ Transaction (طلبان متزامنان).
        if (db.scalar(select(func.count()).select_from(User)) or 0) > 0:
            return redirect("/login")
        now = utcnow()
        user = User(
            username=values["username"],
            full_name=values["full_name"],
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
            db, AuditAction.USER_CREATED, username="(الإعداد الأول)", entity_type="user",
            entity_id=user.id, details={"username": user.username, "role": Role.ADMIN},
            ip=client_ip(request),
        )
    return redirect("/login?msg=setup_done")
