"""Persistência de auditoria. Apenas Postgres – sem ORM pesado."""

from datetime import UTC, datetime

from sqlalchemy import JSON, DateTime, String, Text, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, sessionmaker

from .config import get_settings


class Base(DeclarativeBase):
    pass


class LeadAudit(Base):
    __tablename__ = "lead_audit"

    lead_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    tenant_id: Mapped[str] = mapped_column(String(64), index=True)
    channel: Mapped[str] = mapped_column(String(32))
    external_id: Mapped[str] = mapped_column(String(128), index=True)
    status: Mapped[str] = mapped_column(String(32), default="received")
    syonet_lead_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    syonet_http_status: Mapped[int | None] = mapped_column(nullable=True)
    chatwoot_contact_id: Mapped[int | None] = mapped_column(nullable=True)
    chatwoot_conversation_id: Mapped[int | None] = mapped_column(nullable=True, index=True)
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC)
    )


_engine = None
_SessionLocal: sessionmaker[Session] | None = None


def _init() -> None:
    global _engine, _SessionLocal
    if _engine is None:
        _engine = create_engine(get_settings().database_url, pool_pre_ping=True, future=True)
        _SessionLocal = sessionmaker(bind=_engine, autoflush=False, expire_on_commit=False)


def get_session() -> Session:
    _init()
    assert _SessionLocal is not None
    return _SessionLocal()


def create_all() -> None:
    _init()
    assert _engine is not None
    Base.metadata.create_all(_engine)
