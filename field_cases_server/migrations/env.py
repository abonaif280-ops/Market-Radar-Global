from __future__ import annotations

from alembic import context

from app.config import load_settings
from app.db import make_engine
from app.models import Base

config = context.config
target_metadata = Base.metadata


def run_migrations() -> None:
    url = config.attributes.get("database_url") or load_settings().database_url
    engine = make_engine(url)
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


run_migrations()
