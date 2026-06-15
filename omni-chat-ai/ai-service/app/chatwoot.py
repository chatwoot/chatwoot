"""Thin Chatwoot REST client: post replies, private notes, and trigger human handoff.

Handoff model (verified against Chatwoot source): a bot-owned conversation is `pending`.
Flipping status to `open` calls `bot_handoff!` server-side, which stops the bot and lets a
human agent take over. Flipping back to `pending` returns control to the bot.
"""
from __future__ import annotations

import hashlib
import hmac

import httpx

from . import settings_service


def _url(path: str) -> str:
    base = settings_service.get("chatwoot.base_url").rstrip("/")
    account_id = settings_service.get("chatwoot.account_id")
    return f"{base}/api/v1/accounts/{account_id}{path}"


def _headers() -> dict[str, str]:
    return {"api_access_token": settings_service.get("chatwoot.api_access_token")}


def verify_signature(raw_body: bytes, signature: str | None) -> bool:
    """Validate the HMAC-SHA256 signature Chatwoot sends with agent-bot webhooks."""
    secret = settings_service.get("chatwoot.hmac_secret")
    if not secret:
        return True  # not configured in local dev
    if not signature:
        return False
    expected = hmac.new(secret.encode(), raw_body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)


async def send_reply(conversation_id: int, content: str, private: bool = False) -> None:
    """Post an outgoing message (or a private internal note when private=True)."""
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.post(
            _url(f"/conversations/{conversation_id}/messages"),
            headers=_headers(),
            json={"content": content, "message_type": "outgoing", "private": private},
        )
        resp.raise_for_status()


async def fetch_history(conversation_id: int, limit: int = 10) -> list[dict]:
    """Return recent visible messages (oldest→newest) so the agent has multi-turn context.

    Each item is ``{"incoming": bool, "content": str}``. Private notes and activity messages
    are excluded; only customer (incoming=0) and agent/bot (outgoing=1) text is kept.
    """
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.get(
            _url(f"/conversations/{conversation_id}/messages"),
            headers=_headers(),
        )
        resp.raise_for_status()
    payload = resp.json().get("payload", [])
    msgs = [
        {"incoming": m.get("message_type") == 0, "content": m.get("content") or ""}
        for m in payload
        if m.get("content") and not m.get("private") and m.get("message_type") in (0, 1)
    ]
    return msgs[-limit:]


async def handoff_to_human(conversation_id: int, summary: str) -> None:
    """Tell the customer a human is coming, leave a private summary, then flip pending → open.

    The public line keeps the customer informed (PRD F2); the private note briefs the manager;
    flipping status to ``open`` triggers ``bot_handoff!`` server-side and stops the bot.
    """
    await send_reply(
        conversation_id,
        "Let me bring in a colleague who can help with this — they'll be with you shortly. 🙏",
    )
    await send_reply(conversation_id, f"🤝 Handoff summary: {summary}", private=True)
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.post(
            _url(f"/conversations/{conversation_id}/toggle_status"),
            headers=_headers(),
            json={"status": "open"},
        )
        resp.raise_for_status()
