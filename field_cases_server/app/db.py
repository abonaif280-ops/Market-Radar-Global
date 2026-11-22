"""الاتصال بقاعدة البيانات الخارجية (SQL Server أو PostgreSQL) عبر SQLAlchemy.

أمثلة رابط الاتصال (config.ini ← [database] url):

- PostgreSQL:
  postgresql+psycopg://field_cases:كلمة_المرور@db-server:5432/field_cases
- SQL Server بحساب SQL:
  mssql+pyodbc://field_cases:كلمة_المرور@db-server:1433/field_cases?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes
- SQL Server بحساب Windows (Trusted Connection):
  mssql+pyodbc://@db-server/field_cases?driver=ODBC+Driver+18+for+SQL+Server&trusted_connection=yes&TrustServerCertificate=yes
"""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

SUPPORTED_DIALECTS = ("postgresql", "mssql", "sqlite")


def make_engine(url: str) -> Engine:
    dialect = url.split(":", 1)[0].split("+", 1)[0]
    if dialect not in SUPPORTED_DIALECTS:
        raise ValueError(f"قاعدة البيانات غير مدعومة: {dialect}")
    kwargs: dict = {"pool_pre_ping": True, "future": True}
    if dialect == "sqlite":
        # التشغيل المحلي على جهاز واحد والاختبارات.
        kwargs["connect_args"] = {"check_same_thread": False}
    return create_engine(url, **kwargs)


def make_session_factory(engine: Engine) -> sessionmaker[Session]:
    return sessionmaker(bind=engine, expire_on_commit=False, future=True)


@contextmanager
def session_scope(factory: sessionmaker[Session]) -> Iterator[Session]:
    """Transaction واحدة: Commit عند النجاح، Rollback عند أي خطأ."""
    session = factory()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
