from __future__ import annotations

from fastapi import APIRouter, Request

from .. import audit, security
from ..audit import AuditAction
from ..clock import utcnow
from ..models import UserSession
from ..web import check_csrf, client_ip, current_session, redirect, render, tx

router = APIRouter(prefix="/account")


@router.get("/password")
def password_form(request: Request):
    with tx(request) as db:
        current_session(request, db, allow_password_change=True)
    return render(request, "account/password.html")


@router.post("/password")
async def change_password(request: Request):
    form = await request.form()
    with tx(request) as db:
        active = current_session(request, db, allow_password_change=True)
        check_csrf(active, form)
        user = active.user
        current = str(form.get("current_password", ""))
        new = str(form.get("new_password", ""))
        confirm = str(form.get("confirm_password", ""))
        error = None
        if not security.verify_password(current, user.password_hash):
            error = "كلمة المرور الحالية غير صحيحة"
        elif new != confirm:
            error = "كلمتا المرور الجديدتان غير متطابقتين"
        elif new == current:
            error = "اختر كلمة مرور مختلفة عن الحالية"
        else:
            error = security.validate_password(new, user.username)
        if error:
            return render(request, "account/password.html", {"error": error}, status_code=400)
        user.password_hash = security.hash_password(new)
        user.must_change_password = False
        user.updated_at = utcnow()
        # إنهاء الجلسات الأخرى لهذا المستخدم (أي جهاز آخر يعيد الدخول).
        db.query(UserSession).filter(
            UserSession.user_id == user.id,
            UserSession.token_hash != active.record.token_hash,
        ).delete(synchronize_session=False)
        audit.log(db, AuditAction.PASSWORD_CHANGED, user=user, ip=client_ip(request))
    return redirect("/?msg=password_changed")
