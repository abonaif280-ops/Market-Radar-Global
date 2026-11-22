"""أدوات مشتركة للمسارات: القوالب، الجلسة الحالية، الصلاحيات، CSRF."""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from fastapi import Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from . import security
from .config import Settings
from .db import session_scope
from .models import Role

TEMPLATES_DIR = Path(__file__).parent / "templates"
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))
templates.env.globals["Role"] = Role

SESSION_COOKIE = "fc_session"
LOGIN_CSRF_COOKIE = "fc_login_csrf"

# رسائل ثابتة تُعرض بعد إعادة التوجيه (لا يُعرض نص من الرابط مباشرة).
MESSAGES = {
    "password_changed": "تم تغيير كلمة المرور",
    "user_created": "أُضيف المستخدم",
    "user_updated": "حُفظت التعديلات",
    "user_unlocked": "أُلغي قفل الحساب",
    "logged_out": "تم تسجيل الخروج",
    "session_expired": "انتهت الجلسة، سجّل الدخول مرة أخرى",
}


@dataclass(frozen=True)
class ViewUser:
    """نسخة ثابتة من المستخدم للقوالب (لا تتأثر بإلغاء الـ Transaction عند خطأ)."""

    id: int
    username: str
    full_name: str
    role: str
    role_label: str
    must_change_password: bool


class LoginRequired(Exception):
    """يُحوَّل إلى إعادة توجيه لصفحة الدخول."""


class PasswordChangeRequired(Exception):
    """المستخدم يجب أن يغيّر كلمة المرور قبل أي شيء آخر."""


class Forbidden(Exception):
    """لا يملك المستخدم صلاحية هذه الصفحة."""


class CsrfFailed(Exception):
    """نموذج بدون رمز CSRF صحيح."""


def settings_of(request: Request) -> Settings:
    return request.app.state.settings


def client_ip(request: Request) -> str | None:
    return request.client.host if request.client else None


@contextmanager
def tx(request: Request) -> Iterator[Session]:
    with session_scope(request.app.state.session_factory) as db:
        yield db


def current_session(
    request: Request,
    db: Session,
    *,
    roles: tuple[str, ...] | None = None,
    allow_password_change: bool = False,
) -> security.ActiveSession:
    active = security.load_session(db, settings_of(request), request.cookies.get(SESSION_COOKIE))
    if active is None:
        raise LoginRequired()
    if active.user.must_change_password and not allow_password_change:
        raise PasswordChangeRequired()
    if roles is not None and active.user.role not in roles:
        raise Forbidden()
    user = active.user
    request.state.view_user = ViewUser(
        id=user.id,
        username=user.username,
        full_name=user.full_name,
        role=user.role,
        role_label=user.role_label,
        must_change_password=user.must_change_password,
    )
    request.state.csrf_token = active.record.csrf_token
    return active


def check_csrf(active: security.ActiveSession, form: Any) -> None:
    if not security.csrf_matches(active.record.csrf_token, form.get("csrf_token")):
        raise CsrfFailed()


def render(
    request: Request,
    template: str,
    context: dict[str, Any] | None = None,
    status_code: int = 200,
) -> HTMLResponse:
    ctx = {
        "request": request,
        "user": getattr(request.state, "view_user", None),
        "csrf_token": getattr(request.state, "csrf_token", None),
        "message": MESSAGES.get(request.query_params.get("msg", "")),
    }
    if context:
        ctx.update(context)
    return templates.TemplateResponse(request, template, ctx, status_code=status_code)


def redirect(url: str) -> RedirectResponse:
    return RedirectResponse(url, status_code=303)
