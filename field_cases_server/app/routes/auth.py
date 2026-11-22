from __future__ import annotations

import secrets

from fastapi import APIRouter, Request

from .. import audit, security
from ..audit import AuditAction
from ..web import (
    LOGIN_CSRF_COOKIE,
    SESSION_COOKIE,
    client_ip,
    redirect,
    render,
    settings_of,
    tx,
)

router = APIRouter()


def _login_page(request: Request, error: str | None = None, username: str = "", status: int = 200):
    token = secrets.token_urlsafe(32)
    response = render(
        request,
        "login.html",
        {"login_csrf": token, "error": error, "username": username},
        status_code=status,
    )
    response.set_cookie(
        LOGIN_CSRF_COOKIE,
        token,
        httponly=True,
        samesite="strict",
        secure=settings_of(request).https,
        max_age=1800,
    )
    return response


@router.get("/login")
def login_form(request: Request):
    return _login_page(request)


@router.post("/login")
async def login(request: Request):
    form = await request.form()
    username = str(form.get("username", ""))[:64]
    password = str(form.get("password", ""))[:256]
    if not security.csrf_matches(request.cookies.get(LOGIN_CSRF_COOKIE), str(form.get("login_csrf", ""))):
        return _login_page(request, "انتهت صلاحية الصفحة، حاول مرة أخرى", username, 400)

    settings = settings_of(request)
    ip = client_ip(request)
    with tx(request) as db:
        result = security.authenticate(db, settings, username, password)
        if result.user is None or result.error:
            audit.log(
                db,
                AuditAction.LOGIN_LOCKED if result.locked else AuditAction.LOGIN_FAILED,
                user=result.user,
                username=security.normalize_username(username)[:64],
                ip=ip,
            )
            error = result.error
            token = None
        else:
            # جلسة جديدة دائمًا عند الدخول (يمنع تثبيت الجلسة).
            token = security.create_session(
                db, settings, result.user, ip, request.headers.get("user-agent")
            )
            audit.log(db, AuditAction.LOGIN, user=result.user, ip=ip)
            error = None
            must_change = result.user.must_change_password

    if token is None:
        return _login_page(request, error, username, 401)
    response = redirect("/account/password" if must_change else "/")
    response.set_cookie(
        SESSION_COOKIE,
        token,
        httponly=True,
        samesite="strict",
        secure=settings.https,
    )
    response.delete_cookie(LOGIN_CSRF_COOKIE)
    return response


@router.post("/logout")
async def logout(request: Request):
    form = await request.form()
    token = request.cookies.get(SESSION_COOKIE)
    with tx(request) as db:
        active = security.load_session(db, settings_of(request), token)
        if active and security.csrf_matches(active.record.csrf_token, str(form.get("csrf_token", ""))):
            audit.log(db, AuditAction.LOGOUT, user=active.user, ip=client_ip(request))
            security.end_session(db, token)
    response = redirect("/login?msg=logged_out")
    response.delete_cookie(SESSION_COOKIE)
    return response
