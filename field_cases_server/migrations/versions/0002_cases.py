"""الحالات والقوائم والحقول الخاصة بالنوع والقوالب والصور، مع البيانات الأولية.

Revision ID: 0002
Revises: 0001
"""

import json
from datetime import datetime, timezone

import sqlalchemy as sa
from alembic import op

from app import seed_v1 as seed

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    lookup_items = op.create_table(
        "lookup_items",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("list_key", sa.String(30), nullable=False),
        sa.Column("code", sa.String(60), nullable=False),
        sa.Column("label", sa.Unicode(200), nullable=False),
        sa.Column("parent_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("is_system", sa.Boolean(), nullable=False),
        sa.UniqueConstraint("list_key", "code", name="uq_lookup_list_code"),
    )
    op.create_index("ix_lookup_list", "lookup_items", ["list_key", "is_active", "sort_order"])

    fields = op.create_table(
        "case_type_fields",
        sa.Column("id", sa.String(120), primary_key=True),
        sa.Column("case_type_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=False),
        sa.Column("field_key", sa.String(60), nullable=False),
        sa.Column("label", sa.Unicode(200), nullable=False),
        sa.Column("input_type", sa.String(20), nullable=False),
        sa.Column("options", sa.UnicodeText(), nullable=True),
        sa.Column("is_required", sa.Boolean(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.UniqueConstraint("case_type_id", "field_key", name="uq_type_field"),
    )
    op.create_index("ix_type_fields", "case_type_fields", ["case_type_id", "sort_order"])

    templates = op.create_table(
        "text_templates",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("case_type_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=True),
        sa.Column("name", sa.Unicode(200), nullable=False),
        sa.Column("body", sa.UnicodeText(), nullable=False),
        sa.Column("is_default", sa.Boolean(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )

    op.create_table(
        "cases",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("display_code", sa.String(24), nullable=False),
        sa.Column("case_type_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=False),
        sa.Column("occurred_at", sa.DateTime(), nullable=False),
        sa.Column("governorate_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=True),
        sa.Column("center_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=True),
        sa.Column("location_text", sa.Unicode(500), nullable=True),
        sa.Column("report_source_id", sa.String(80), sa.ForeignKey("lookup_items.id"), nullable=True),
        sa.Column("location_description", sa.UnicodeText(), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("case_info", sa.UnicodeText(), nullable=True),
        sa.Column("action_taken", sa.UnicodeText(), nullable=True),
        sa.Column("has_injuries", sa.Boolean(), nullable=False),
        sa.Column("injuries_count", sa.Integer(), nullable=False),
        sa.Column("has_deaths", sa.Boolean(), nullable=False),
        sa.Column("deaths_count", sa.Integer(), nullable=False),
        sa.Column("has_damage", sa.Boolean(), nullable=False),
        sa.Column("damage_description", sa.UnicodeText(), nullable=True),
        sa.Column("notes", sa.UnicodeText(), nullable=True),
        sa.Column("extra_fields", sa.UnicodeText(), nullable=False),
        sa.Column("generated_text", sa.UnicodeText(), nullable=True),
        sa.Column("final_text", sa.UnicodeText(), nullable=True),
        sa.Column("is_text_edited", sa.Boolean(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("revision", sa.Integer(), nullable=False),
        sa.Column("created_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("updated_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_cases_active_occurred", "cases", ["deleted_at", "occurred_at"])
    op.create_index("ix_cases_display_code", "cases", ["display_code"])
    op.create_index("ix_cases_created_by", "cases", ["created_by"])
    op.create_index("ix_cases_type", "cases", ["case_type_id"])

    op.create_table(
        "case_parties",
        sa.Column("case_id", sa.String(36), sa.ForeignKey("cases.id"), primary_key=True),
        sa.Column("party_id", sa.String(80), sa.ForeignKey("lookup_items.id"), primary_key=True),
    )

    op.create_table(
        "attachments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("case_id", sa.String(36), sa.ForeignKey("cases.id"), nullable=False),
        sa.Column("seq", sa.Integer(), nullable=False),
        sa.Column("file_name", sa.String(80), nullable=False),
        sa.Column("relative_path", sa.String(300), nullable=False),
        sa.Column("mime_type", sa.String(50), nullable=False),
        sa.Column("size_bytes", sa.Integer(), nullable=False),
        sa.Column("sha256", sa.String(64), nullable=False),
        sa.Column("created_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.UniqueConstraint("case_id", "seq", name="uq_attachment_seq"),
    )
    op.create_index("ix_attachments_case", "attachments", ["case_id"])

    # ---------------------------------------------------- البيانات الأولية
    # الأب قبل الابن (المراكز بعد المحافظات) حتى لا يُخرق المفتاح الأجنبي.
    order: dict[str, int] = {}
    rows = []
    for list_key, code, label, parent in seed.LOOKUPS:
        order[list_key] = order.get(list_key, 0) + 10
        rows.append(
            {
                "id": seed.lookup_id(list_key, code),
                "list_key": list_key,
                "code": code,
                "label": label,
                "parent_id": seed.lookup_id(seed.GOVERNORATE, parent) if parent else None,
                "sort_order": order[list_key],
                "is_active": True,
                "is_system": True,
            }
        )
    op.bulk_insert(lookup_items, [r for r in rows if r["parent_id"] is None])
    op.bulk_insert(lookup_items, [r for r in rows if r["parent_id"] is not None])

    op.bulk_insert(
        fields,
        [
            {
                "id": f"field:{type_code}:{key}",
                "case_type_id": seed.lookup_id(seed.CASE_TYPE, type_code),
                "field_key": key,
                "label": label,
                "input_type": input_type,
                "options": json.dumps(options, ensure_ascii=False) if options else None,
                "is_required": False,
                "sort_order": (i + 1) * 10,
                "is_active": True,
            }
            for i, (type_code, key, label, input_type, options) in enumerate(seed.FIELDS)
        ],
    )

    now = datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)
    op.bulk_insert(
        templates,
        [
            {
                "id": f"template:{type_code}" if type_code else seed.GENERIC_TEMPLATE_ID,
                "case_type_id": seed.lookup_id(seed.CASE_TYPE, type_code) if type_code else None,
                "name": name,
                "body": body,
                "is_default": True,
                "is_active": True,
                "updated_at": now,
            }
            for type_code, (name, body) in seed.TEMPLATES.items()
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_attachments_case", table_name="attachments")
    op.drop_table("attachments")
    op.drop_table("case_parties")
    for name in ("ix_cases_type", "ix_cases_created_by", "ix_cases_display_code", "ix_cases_active_occurred"):
        op.drop_index(name, table_name="cases")
    op.drop_table("cases")
    op.drop_table("text_templates")
    op.drop_index("ix_type_fields", table_name="case_type_fields")
    op.drop_table("case_type_fields")
    op.drop_index("ix_lookup_list", table_name="lookup_items")
    op.drop_table("lookup_items")
