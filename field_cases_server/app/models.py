"""جداول قاعدة البيانات.

الأنواع مختارة لتعمل على SQL Server و PostgreSQL بنفس الشكل:
- النصوص العربية Unicode/UnicodeText (NVARCHAR على SQL Server).
- التواريخ UTC بدون منطقة زمنية.
"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Unicode,
    UnicodeText,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Role:
    ADMIN = "admin"
    SUPERVISOR = "supervisor"
    ENTRY = "entry"

    ALL = (ADMIN, SUPERVISOR, ENTRY)
    LABELS = {
        ADMIN: "مدير النظام",
        SUPERVISOR: "مشرف",
        ENTRY: "مُدخل بيانات",
    }


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    # يُخزَّن بأحرف صغيرة حتى لا يتكرر المستخدم باختلاف حالة الأحرف.
    username: Mapped[str] = mapped_column(Unicode(64), unique=True, nullable=False)
    full_name: Mapped[str] = mapped_column(Unicode(200), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    must_change_password: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    failed_attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    @property
    def role_label(self) -> str:
        return Role.LABELS.get(self.role, self.role)


class UserSession(Base):
    """جلسة دخول. يُخزَّن SHA-256 للرمز فقط؛ الرمز نفسه في الكوكي لدى المستخدم."""

    __tablename__ = "user_sessions"
    __table_args__ = (Index("ix_user_sessions_user", "user_id"),)

    token_hash: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    csrf_token: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    ip: Mapped[str | None] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(Unicode(300), nullable=True)


class AuditLog(Base):
    __tablename__ = "audit_log"
    __table_args__ = (
        Index("ix_audit_at", "at"),
        Index("ix_audit_entity", "entity_type", "entity_id"),
    )

    id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True
    )
    at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    user_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    username: Mapped[str | None] = mapped_column(Unicode(64), nullable=True)
    action: Mapped[str] = mapped_column(String(50), nullable=False)
    entity_type: Mapped[str | None] = mapped_column(String(30), nullable=True)
    entity_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    details: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    ip: Mapped[str | None] = mapped_column(String(45), nullable=True)


class AppSetting(Base):
    __tablename__ = "app_settings"

    key: Mapped[str] = mapped_column(String(100), primary_key=True)
    value: Mapped[str] = mapped_column(UnicodeText, nullable=False)
