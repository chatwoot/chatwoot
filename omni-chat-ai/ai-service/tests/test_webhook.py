"""Smoke tests for the webhook surface (no live LLM/Chatwoot calls)."""
from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    assert client.get("/health").json() == {"status": "ok"}


def test_ignores_non_message_events() -> None:
    resp = client.post("/webhooks/chatwoot", json={"event": "conversation_opened"})
    assert resp.status_code == 204


def test_ignores_outgoing_messages() -> None:
    resp = client.post(
        "/webhooks/chatwoot",
        json={"event": "message_created", "message_type": "outgoing", "content": "hi"},
    )
    assert resp.status_code == 204
