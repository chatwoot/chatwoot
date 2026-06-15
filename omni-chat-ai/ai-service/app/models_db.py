"""ORM tables for the settings store and admin panel."""
from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, LargeBinary, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class AppSetting(Base):
    """A single configuration value. Secrets are stored Fernet-encrypted in ``encrypted_value``;
    non-secret values use ``value``. Keys are namespaced strings, e.g. ``keycrm.api_key``."""

    __tablename__ = "app_settings"

    key: Mapped[str] = mapped_column(String(128), primary_key=True)
    value: Mapped[str | None] = mapped_column(Text, nullable=True)
    encrypted_value: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
    is_secret: Mapped[bool] = mapped_column(Boolean, default=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class AdminUser(Base):
    """The single panel administrator, created in the first-run setup wizard."""

    __tablename__ = "admin_user"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class AgentPrompt(Base):
    """Editable system prompt + model selection for each specialist agent."""

    __tablename__ = "agent_prompt"

    agent: Mapped[str] = mapped_column(String(64), primary_key=True)
    system_prompt: Mapped[str] = mapped_column(Text)
    model: Mapped[str] = mapped_column(String(64), default="claude-primary")
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class KbDocument(Base):
    """Knowledge-base document metadata; chunks/vectors live in Qdrant."""

    __tablename__ = "kb_document"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    source: Mapped[str] = mapped_column(String(64), default="upload")
    status: Mapped[str] = mapped_column(String(32), default="pending")
    chunks: Mapped[int] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
