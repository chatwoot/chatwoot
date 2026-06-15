"""E-Chat connector adapter + outbound webhook handling (HTTP mocked)."""
from __future__ import annotations

from app.connectors import echat


def test_parse_inbound_maps_fields():
    out = echat._parse_inbound({"from": "u123", "name": "Olena", "text": "Привіт"})
    assert out == ("u123", "Olena", "Привіт")


def test_parse_inbound_ignores_incomplete():
    assert echat._parse_inbound({"from": "u1"}) is None
    assert echat._parse_inbound({"text": "hi"}) is None


async def test_send_to_echat_noop_without_credentials(monkeypatch):
    from app import settings_service

    # No api key configured → must not attempt any HTTP call (would raise if it did).
    settings_service._cache.pop("echat.api_key", None)
    monkeypatch.setattr(settings_service, "get", lambda k: "" if k == "echat.api_key" else "x")
    await echat.send_to_echat("u1", "hello")  # should simply return
