"""سجل العمليات: من فعل ماذا ومتى ومن أي جهاز."""

from __future__ import annotations

import json
from typing import Any

from sqlalchemy.orm import Session

from .clock import utcnow
from .models import AuditLog, User


class AuditAction:
    LOGIN = "login"
    LOGIN_FAILED = "login_failed"
    LOGIN_LOCKED = "login_locked"
    LOGOUT = "logout"
    PASSWORD_CHANGED = "password_changed"
    USER_CREATED = "user_created"
    USER_UPDATED = "user_updated"
    PASSWORD_RESET = "password_reset"


def log(
    db: Session,
    action: str,
    *,
    user: User | None = None,
    username: str | None = None,
    entity_type: str | None = None,
    entity_id: str | int | None = None,
    details: dict[str, Any] | None = None,
    ip: str | None = None,
) -> None:
    """يُستدعى داخل نفس Transaction العملية حتى لا يُسجَّل ما لم يحدث."""
    db.add(
        AuditLog(
            at=utcnow(),
            user_id=user.id if user else None,
            username=user.username if user else username,
            action=action,
            entity_type=entity_type,
            entity_id=None if entity_id is None else str(entity_id),
            details=None if details is None else json.dumps(details, ensure_ascii=False),
            ip=ip,
        )
    )
