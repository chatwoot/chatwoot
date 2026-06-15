"""Async SQLAlchemy engine/session for the settings + admin store.

A small Postgres-backed store on its own ``omni_ai`` database holds encrypted API keys, the
single admin account, editable agent prompts, and knowledge-base document metadata. Tables are
created on startup (``init_models``) — light enough that we don't need migrations yet.
"""
from __future__ import annotations

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from .config import settings

engine = create_async_engine(settings.omni_database_url, pool_pre_ping=True)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def init_models() -> None:
    """Create tables if they don't exist. Imported models register their metadata first."""
    from . import models_db  # noqa: F401  (registers tables on Base.metadata)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_session() -> AsyncIterator[AsyncSession]:
    async with SessionLocal() as session:
        yield session
