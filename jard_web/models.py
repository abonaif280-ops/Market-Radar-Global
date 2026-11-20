# -*- coding: utf-8 -*-
"""جداول قاعدة البيانات"""
from datetime import datetime

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.dialects import mysql

db = SQLAlchemy()

# نص طويل: LONGTEXT في MySQL (للشعار والتوقيعات) و TEXT في غيرها
BigText = db.Text().with_variant(mysql.LONGTEXT(), "mysql")

# ترميز كامل للعربية في MySQL
MY = {"mysql_charset": "utf8mb4", "mysql_collate": "utf8mb4_unicode_ci"}

ROLE_ADMIN, ROLE_CHAIR, ROLE_MEMBER = "admin", "chair", "member"
ROLE_LABELS = {ROLE_ADMIN: "مدير النظام", ROLE_CHAIR: "رئيس اللجنة", ROLE_MEMBER: "مندوب"}


class User(db.Model):
    __tablename__ = "users"
    __table_args__ = MY
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    pw_ver = db.Column(db.Integer, default=1, nullable=False)
    default_pw = db.Column(db.Boolean, default=False, nullable=False)
    name = db.Column(db.String(200), default="", nullable=False)
    rank = db.Column(db.String(100), default="", nullable=False)
    role = db.Column(db.String(20), default=ROLE_MEMBER, nullable=False)
    active = db.Column(db.Boolean, default=True, nullable=False)
    sig = db.Column(BigText)
    sig_at = db.Column(db.String(40), default="")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

    @property
    def full(self):
        """صلاحية كاملة على البيانات (الإعدادات، التقرير، الحذف)"""
        return self.role in (ROLE_ADMIN, ROLE_CHAIR)

    @property
    def is_admin(self):
        return self.role == ROLE_ADMIN

    @property
    def role_label(self):
        return ROLE_LABELS.get(self.role, self.role)


class KV(db.Model):
    """إعدادات عامة بصيغة JSON: الترويسة، التقرير، الأنواع، المستودعات، قرار اللجنة، رقم الإصدار"""
    __tablename__ = "kv"
    __table_args__ = MY
    key = db.Column(db.String(64), primary_key=True)
    value = db.Column(BigText)


class Item(db.Model):
    """قائمة الأصناف المسجلة"""
    __tablename__ = "items"
    id = db.Column(db.Integer, primary_key=True)
    cat = db.Column(db.String(200), default="", nullable=False)
    name = db.Column(db.String(300), nullable=False)
    __table_args__ = (db.UniqueConstraint("cat", "name", name="uq_item"), MY)


class Entity(db.Model):
    """الجهات"""
    __tablename__ = "entities"
    __table_args__ = MY
    id = db.Column(db.String(40), primary_key=True)
    name = db.Column(db.String(300), nullable=False, default="")
    location = db.Column(db.String(300), default="")
    rep = db.Column(db.String(200), default="")
    phone = db.Column(db.String(50), default="")
    rep_sig = db.Column(BigText)
    rep_sig_at = db.Column(db.String(40), default="")
    date = db.Column(db.String(20), default="")
    warehouses = db.Column(db.Text)   # JSON
    delegates = db.Column(db.Text)    # JSON
    notes = db.Column(db.Text)
    created = db.Column(db.String(40), default="")
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Row(db.Model):
    """أصناف الجرد لكل جهة"""
    __tablename__ = "rows"
    __table_args__ = MY
    id = db.Column(db.String(40), primary_key=True)
    entity_id = db.Column(db.String(40), index=True, nullable=False)
    pos = db.Column(db.Integer, default=0)
    cat = db.Column(db.String(200), default="")
    name = db.Column(db.String(300), default="")
    serial = db.Column(db.String(200), default="")
    wh = db.Column(db.String(200), default="")
    book = db.Column(db.String(30), default="0")
    actual = db.Column(db.String(30), default="")
    notes = db.Column(db.Text)
    by_ref = db.Column(db.String(40), default="")
    by_name = db.Column(db.String(200), default="")
    at = db.Column(db.String(40), default="")
    updated = db.Column(db.String(40), default="")
    created_by = db.Column(db.Integer)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Note(db.Model):
    """ملاحظات الجرد السريعة"""
    __tablename__ = "notes"
    __table_args__ = MY
    id = db.Column(db.String(40), primary_key=True)
    entity = db.Column(db.String(300), default="")
    date = db.Column(db.String(20), default="")
    cat = db.Column(db.String(200), default="")
    name = db.Column(db.String(300), default="")
    book = db.Column(db.String(30), default="0")
    actual = db.Column(db.String(30), default="")
    notes = db.Column(db.Text)
    by_name = db.Column(db.String(200), default="")
    by_user = db.Column(db.Integer)
    merged = db.Column(db.Boolean, default=False)
    created = db.Column(db.String(40), default="")
    updated = db.Column(db.String(40), default="")


class Log(db.Model):
    """سجل العمليات (الدخول والحفظ)"""
    __tablename__ = "log"
    __table_args__ = MY
    id = db.Column(db.Integer, primary_key=True)
    at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    user_id = db.Column(db.Integer)
    username = db.Column(db.String(64), default="")
    action = db.Column(db.String(40), default="")
    detail = db.Column(db.Text)
    ip = db.Column(db.String(64), default="")
