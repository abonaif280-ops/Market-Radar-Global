"""كلمات المرور وجلسات الدخول وقفل الحسابات.

- كلمات المرور: Argon2id (argon2-cffi)؛ لا تُخزَّن كلمة المرور نفسها أبدًا.
- الجلسة: رمز عشوائي 256-bit في كوكي HttpOnly؛ القاعدة تحفظ SHA-256 له فقط،
  فتسريب جدول الجلسات لا يكفي لانتحال مستخدم.
- CSRF: رمز لكل جلسة يُرسل مع كل نموذج POST.
- القفل: بعد عدد محاولات خاطئة يُقفل الحساب مؤقتًا، برسالة لا تكشف إن كان
  الاسم موجودًا.
"""

from __future__ import annotations

import hashlib
import hmac
import re
import secrets
from dataclasses import dataclass
from datetime import timedelta

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from .clock import utcnow
from .config import Settings
from .models import User, UserSession

_hasher = PasswordHasher()
# تجزئة ثابتة تُستخدم عند عدم وجود المستخدم حتى يتساوى زمن الاستجابة.
_DUMMY_HASH = _hasher.hash(secrets.token_urlsafe(16))

MIN_PASSWORD_LENGTH = 10
USERNAME_RE = re.compile(r"^[a-z0-9._-]{3,64}$")


def normalize_username(value: str) -> str:
    return value.strip().lower()


def validate_username(value: str) -> str | None:
    if not USERNAME_RE.match(value):
        return "اسم المستخدم 3 أحرف على الأقل: أحرف إنجليزية صغيرة وأرقام و . _ - فقط"
    return None


def validate_password(password: str, username: str | None = None) -> str | None:
    """يعيد رسالة الخطأ أو None إذا كانت كلمة المرور مقبولة."""
    if len(password) < MIN_PASSWORD_LENGTH:
        return f"كلمة المرور {MIN_PASSWORD_LENGTH} أحرف على الأقل"
    if not re.search(r"[A-Za-z؀-ۿ]", password) or not re.search(r"\d", password):
        return "كلمة المرور يجب أن تحتوي حروفًا وأرقامًا"
    if username and username.lower() in password.lower():
        return "كلمة المرور يجب ألا تحتوي اسم المستخدم"
    return None


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, stored: str) -> bool:
    try:
        return _hasher.verify(stored, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def _token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


# ------------------------------------------------------------------ الدخول


@dataclass
class LoginResult:
    user: User | None = None
    locked: bool = False
    error: str | None = None


GENERIC_LOGIN_ERROR = "اسم المستخدم أو كلمة المرور غير صحيحة"


def authenticate(db: Session, settings: Settings, username: str, password: str) -> LoginResult:
    username = normalize_username(username)
    user = db.scalar(select(User).where(User.username == username))
    now = utcnow()
    if user is None or not user.is_active:
        verify_password(password, _DUMMY_HASH)
        return LoginResult(error=GENERIC_LOGIN_ERROR)
    if user.locked_until and user.locked_until > now:
        return LoginResult(
            user=user,
            locked=True,
            error="الحساب مقفل مؤقتًا بسبب محاولات خاطئة. حاول لاحقًا أو راجع مدير النظام.",
        )
    if not verify_password(password, user.password_hash):
        user.failed_attempts += 1
        if user.failed_attempts >= settings.max_login_attempts:
            user.locked_until = now + timedelta(minutes=settings.lockout_minutes)
            user.failed_attempts = 0
            return LoginResult(
                user=user,
                locked=True,
                error="الحساب مقفل مؤقتًا بسبب محاولات خاطئة. حاول لاحقًا أو راجع مدير النظام.",
            )
        return LoginResult(user=user, error=GENERIC_LOGIN_ERROR)
    user.failed_attempts = 0
    user.locked_until = None
    user.last_login_at = now
    if _hasher.check_needs_rehash(user.password_hash):
        user.password_hash = hash_password(password)
    return LoginResult(user=user)


# ------------------------------------------------------------------ الجلسات


@dataclass
class ActiveSession:
    user: User
    record: UserSession


def create_session(
    db: Session, settings: Settings, user: User, ip: str | None, user_agent: str | None
) -> str:
    """ينشئ جلسة ويعيد الرمز الذي يوضع في الكوكي."""
    token = secrets.token_urlsafe(32)
    now = utcnow()
    db.add(
        UserSession(
            token_hash=_token_hash(token),
            user_id=user.id,
            csrf_token=secrets.token_urlsafe(32),
            created_at=now,
            last_seen_at=now,
            expires_at=now + timedelta(hours=settings.session_max_hours),
            ip=ip,
            user_agent=(user_agent or "")[:300] or None,
        )
    )
    return token


def load_session(db: Session, settings: Settings, token: str | None) -> ActiveSession | None:
    if not token or len(token) > 200:
        return None
    record = db.get(UserSession, _token_hash(token))
    if record is None:
        return None
    now = utcnow()
    idle_limit = record.last_seen_at + timedelta(minutes=settings.session_idle_minutes)
    if now >= record.expires_at or now >= idle_limit:
        db.delete(record)
        return None
    user = db.get(User, record.user_id)
    if user is None or not user.is_active:
        db.delete(record)
        return None
    # تحديث آخر نشاط بدقة دقيقة لتقليل الكتابة.
    if (now - record.last_seen_at).total_seconds() >= 60:
        record.last_seen_at = now
    return ActiveSession(user=user, record=record)


def end_session(db: Session, token: str | None) -> None:
    if token:
        db.execute(delete(UserSession).where(UserSession.token_hash == _token_hash(token)))


def end_all_sessions(db: Session, user_id: int) -> None:
    db.execute(delete(UserSession).where(UserSession.user_id == user_id))


def purge_expired_sessions(db: Session) -> None:
    db.execute(delete(UserSession).where(UserSession.expires_at <= utcnow()))


def csrf_matches(expected: str | None, received: str | None) -> bool:
    return bool(expected and received and hmac.compare_digest(expected, received))
