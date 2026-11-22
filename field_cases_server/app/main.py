"""تطبيق الويب: FastAPI + قوالب HTML من السيرفر نفسه، بلا أي موارد خارجية."""

from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from starlette.exceptions import HTTPException as StarletteHTTPException

from . import __version__
from .config import Settings, load_settings
from .db import make_engine, make_session_factory
from .routes import account, auth, cases, home, users
from .web import (
    CsrfFailed,
    Forbidden,
    LoginRequired,
    PasswordChangeRequired,
    redirect,
    render,
)

# كل الموارد من السيرفر نفسه فقط: لا خطوط ولا مكتبات من الإنترنت.
CSP = (
    "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; "
    "object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"
)


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or load_settings()
    # لا صفحات توثيق تلقائية: تعتمد على مكتبات من الإنترنت ولا حاجة لها.
    app = FastAPI(title="الحالات الميدانية", docs_url=None, redoc_url=None, openapi_url=None)
    engine = make_engine(settings.database_url)
    app.state.settings = settings
    app.state.engine = engine
    app.state.session_factory = make_session_factory(engine)

    app.mount("/static", StaticFiles(directory=str(_static_dir())), name="static")
    for module in (auth, home, account, users, cases):
        app.include_router(module.router)

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["Content-Security-Policy"] = CSP
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        if not request.url.path.startswith("/static/"):
            response.headers["Cache-Control"] = "no-store"
        if settings.https:
            response.headers["Strict-Transport-Security"] = "max-age=31536000"
        return response

    @app.exception_handler(LoginRequired)
    async def _login(request: Request, exc: LoginRequired):
        return redirect("/login")

    @app.exception_handler(PasswordChangeRequired)
    async def _password(request: Request, exc: PasswordChangeRequired):
        return redirect("/account/password")

    @app.exception_handler(Forbidden)
    async def _forbidden(request: Request, exc: Forbidden):
        return render(
            request,
            "error.html",
            {"title": "غير مسموح", "detail": "لا تملك صلاحية هذه الصفحة."},
            status_code=403,
        )

    @app.exception_handler(CsrfFailed)
    async def _csrf(request: Request, exc: CsrfFailed):
        return render(
            request,
            "error.html",
            {"title": "انتهت صلاحية النموذج", "detail": "أعد فتح الصفحة وحاول مرة أخرى."},
            status_code=400,
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(request: Request, exc: StarletteHTTPException):
        if exc.status_code == 404:
            return render(
                request,
                "error.html",
                {"title": "الصفحة غير موجودة", "detail": ""},
                status_code=404,
            )
        return HTMLResponse(str(exc.detail), status_code=exc.status_code)

    @app.get("/health", include_in_schema=False)
    def health():
        """لفحص التشغيل من السيرفر: يعيد حالة الاتصال بقاعدة البيانات."""
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return {"status": "ok", "version": __version__}
        except Exception:
            return JSONResponse({"status": "database_unavailable"}, status_code=503)

    return app


def _static_dir():
    from pathlib import Path

    return Path(__file__).parent / "static"
