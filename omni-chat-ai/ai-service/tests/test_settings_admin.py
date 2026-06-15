"""Tests for the settings store, encryption, and admin auth (no live services)."""
from __future__ import annotations

import httpx
import pytest
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app import auth, crypto, db, provisioning, settings_service
from app.config import settings as env_settings


@pytest.fixture
async def sqlite_db(tmp_path, monkeypatch):
    """Point the DB layer at a throwaway SQLite file and create the schema."""
    engine = create_async_engine(f"sqlite+aiosqlite:///{tmp_path/'t.db'}")
    SessionLocal = async_sessionmaker(engine, expire_on_commit=False)
    monkeypatch.setattr(db, "engine", engine)
    monkeypatch.setattr(db, "SessionLocal", SessionLocal)
    async with engine.begin() as conn:
        from app.db import Base
        from app import models_db  # noqa: F401  (registers tables)

        await conn.run_sync(Base.metadata.create_all)
    settings_service._cache.clear()
    yield
    settings_service._cache.clear()


def test_crypto_round_trip():
    token = crypto.seal("super-secret-key")
    assert crypto.open_secret(token) == "super-secret-key"
    assert isinstance(token, bytes) and token != b"super-secret-key"


def test_get_uses_env_fallback_when_unset():
    settings_service._cache.clear()
    # Registry default is used when nothing is saved and no env override exists.
    assert settings_service.get("keycrm.base_url") == str(env_settings.keycrm_base_url)
    # An unsaved key falls back to its mapped environment attribute.
    assert settings_service.get("keycrm.api_key") == str(env_settings.keycrm_api_key)
    # A key with no value, no env, and no default resolves to empty.
    assert settings_service.get("does.not.exist") == ""


async def test_set_value_persists_and_refresh_loads(sqlite_db):
    await settings_service.set_value("keycrm.api_key", "live-key-123")
    assert settings_service.get("keycrm.api_key") == "live-key-123"
    # Clear cache and reload from DB to prove it persisted (and decrypts).
    settings_service._cache.clear()
    await settings_service.refresh()
    assert settings_service.get("keycrm.api_key") == "live-key-123"


async def test_secret_is_encrypted_at_rest(sqlite_db):
    await settings_service.set_value("ai.api_key", "sk-ant-plain")
    async with db.SessionLocal() as session:
        from app.models_db import AppSetting

        row = await session.get(AppSetting, "ai.api_key")
    assert row.is_secret is True
    assert row.value is None
    assert row.encrypted_value is not None
    assert b"sk-ant-plain" not in row.encrypted_value


async def test_register_llm_model_creates_aliases(monkeypatch):
    settings_service._cache.update({
        "ai.api_key": "sk-ant-live", "ai.provider": "anthropic", "ai.model": "claude-sonnet-4-6",
    })
    created: list[dict] = []

    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path == "/model/info":
            return httpx.Response(200, json={"data": []})  # nothing to clean up
        if request.url.path == "/model/new":
            import json
            created.append(json.loads(request.content))
            return httpx.Response(200, json={"model_id": "x"})
        return httpx.Response(404)

    real_client = httpx.AsyncClient

    def fake_client(*args, **kwargs):
        return real_client(transport=httpx.MockTransport(handler))

    monkeypatch.setattr(provisioning.httpx, "AsyncClient", fake_client)
    try:
        ok, msg = await provisioning.register_llm_model()
    finally:
        for k in ("ai.api_key", "ai.provider", "ai.model"):
            settings_service._cache.pop(k, None)

    assert ok, msg
    names = {c["model_name"] for c in created}
    assert names == {"claude-primary", "claude-fast"}
    primary = next(c for c in created if c["model_name"] == "claude-primary")
    assert primary["litellm_params"]["model"] == "anthropic/claude-sonnet-4-6"
    assert primary["litellm_params"]["api_key"] == "sk-ant-live"


def test_password_hash_and_session():
    h = auth.hash_password("hunter2pass")
    assert auth.verify_password("hunter2pass", h)
    assert not auth.verify_password("wrong", h)
    token = auth.issue_session("admin@example.com")

    class _Req:
        cookies = {auth.COOKIE_NAME: token}

    assert auth.read_session(_Req()) == "admin@example.com"
