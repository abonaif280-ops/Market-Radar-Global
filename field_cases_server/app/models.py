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
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Unicode,
    UnicodeText,
    UniqueConstraint,
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


# ---------------------------------------------------------------- الحالات (ح2)
# المعرفات النصية للقوائم والقوالب مطابقة لتطبيق الجوال (مثل case_type:FIRE)
# حتى تتوافق حزم .casepkg لاحقًا.


class LookupItem(Base):
    """القوائم: أنواع الحالات، المحافظات، المراكز، مصادر البلاغ، الجهات."""

    __tablename__ = "lookup_items"
    __table_args__ = (
        UniqueConstraint("list_key", "code", name="uq_lookup_list_code"),
        Index("ix_lookup_list", "list_key", "is_active", "sort_order"),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    list_key: Mapped[str] = mapped_column(String(30), nullable=False)
    code: Mapped[str] = mapped_column(String(60), nullable=False)
    label: Mapped[str] = mapped_column(Unicode(200), nullable=False)
    parent_id: Mapped[str | None] = mapped_column(ForeignKey("lookup_items.id"), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_system: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)


class CaseTypeField(Base):
    """حقول إضافية خاصة بكل نوع حالة (مثل "حالة الجسم" للجسم الصلب)."""

    __tablename__ = "case_type_fields"
    __table_args__ = (
        UniqueConstraint("case_type_id", "field_key", name="uq_type_field"),
        Index("ix_type_fields", "case_type_id", "sort_order"),
    )

    id: Mapped[str] = mapped_column(String(120), primary_key=True)
    case_type_id: Mapped[str] = mapped_column(ForeignKey("lookup_items.id"), nullable=False)
    field_key: Mapped[str] = mapped_column(String(60), nullable=False)
    label: Mapped[str] = mapped_column(Unicode(200), nullable=False)
    input_type: Mapped[str] = mapped_column(String(20), nullable=False)
    options: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)  # JSON
    is_required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class TextTemplate(Base):
    """قوالب الصياغة الآلية. case_type_id فارغ = القالب العام."""

    __tablename__ = "text_templates"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    case_type_id: Mapped[str | None] = mapped_column(ForeignKey("lookup_items.id"), nullable=True)
    name: Mapped[str] = mapped_column(Unicode(200), nullable=False)
    body: Mapped[str] = mapped_column(UnicodeText, nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class CaseStatus:
    DRAFT = "draft"
    COMPLETED = "completed"
    LABELS = {DRAFT: "مسودة", COMPLETED: "مكتملة"}


class Case(Base):
    __tablename__ = "cases"
    __table_args__ = (
        Index("ix_cases_active_occurred", "deleted_at", "occurred_at"),
        Index("ix_cases_display_code", "display_code"),
        Index("ix_cases_created_by", "created_by"),
        Index("ix_cases_type", "case_type_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)  # UUID
    display_code: Mapped[str] = mapped_column(String(24), nullable=False)
    case_type_id: Mapped[str] = mapped_column(ForeignKey("lookup_items.id"), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)  # UTC
    governorate_id: Mapped[str | None] = mapped_column(ForeignKey("lookup_items.id"), nullable=True)
    center_id: Mapped[str | None] = mapped_column(ForeignKey("lookup_items.id"), nullable=True)
    location_text: Mapped[str | None] = mapped_column(Unicode(500), nullable=True)
    report_source_id: Mapped[str | None] = mapped_column(ForeignKey("lookup_items.id"), nullable=True)
    location_description: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    case_info: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    action_taken: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    has_injuries: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    injuries_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    has_deaths: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    deaths_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    has_damage: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    damage_description: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    notes: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    extra_fields: Mapped[str] = mapped_column(UnicodeText, nullable=False, default="{}")  # JSON
    generated_text: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    final_text: Mapped[str | None] = mapped_column(UnicodeText, nullable=True)
    is_text_edited: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    # يزيد مع كل حفظ؛ يمنع أن يمسح مستخدم تعديلات مستخدم آخر دون أن يعلم.
    revision: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    created_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    updated_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class CaseParty(Base):
    """الجهات التي تمت مباشرتها في الحالة."""

    __tablename__ = "case_parties"

    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), primary_key=True)
    party_id: Mapped[str] = mapped_column(ForeignKey("lookup_items.id"), primary_key=True)


class Attachment(Base):
    __tablename__ = "attachments"
    __table_args__ = (
        UniqueConstraint("case_id", "seq", name="uq_attachment_seq"),
        Index("ix_attachments_case", "case_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), nullable=False)
    seq: Mapped[int] = mapped_column(Integer, nullable=False)
    file_name: Mapped[str] = mapped_column(String(80), nullable=False)
    # مسار نسبي داخل مجلد البيانات؛ لا يُخزَّن مسار مطلق.
    relative_path: Mapped[str] = mapped_column(String(300), nullable=False)
    mime_type: Mapped[str] = mapped_column(String(50), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    created_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
