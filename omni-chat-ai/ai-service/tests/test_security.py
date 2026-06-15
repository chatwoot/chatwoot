"""CSRF protection and connector webhook authentication."""
from __future__ import annotations

from fastapi.testclient import TestClient

from app import auth, settings_service
from app.main import app

client = TestClient(app)


def test_csrf_ok_matches_session_token():
    token = auth.issue_session("a@b.com")

    class _Req:
        cookies = {auth.COOKIE_NAME: token}

    req = _Req()
    expected = auth.csrf_token(req)
    assert expected  # a non-empty per-session token
    assert auth.csrf_ok(req, expected) is True
    assert auth.csrf_ok(req, "wrong") is False
    assert auth.csrf_ok(req, None) is False


def test_settings_post_without_csrf_is_forbidden():
    # Authenticated (valid session cookie) but missing CSRF token → 403, no state change.
    client.cookies.set(auth.COOKIE_NAME, auth.issue_session("a@b.com"))
    resp = client.post("/admin/settings", data={"keycrm.api_key": "x"})
    client.cookies.clear()
    assert resp.status_code == 403


def test_echat_inbound_requires_secret_when_configured():
    settings_service._cache["echat.webhook_secret"] = "s3cret"
    try:
        bad = client.post("/connectors/echat/inbound?token=nope", json={"text": "hi"})
        good = client.post("/connectors/echat/inbound?token=s3cret", json={"text": "hi"})
    finally:
        settings_service._cache.pop("echat.webhook_secret", None)
    assert bad.status_code == 401
    assert good.status_code == 200
