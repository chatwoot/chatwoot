"""Thin Chatwoot REST client: post replies, private notes, and trigger human handoff.

Handoff model (verified against Chatwoot source): a bot-owned conversation is `pending`.
Flipping status to `open` calls `bot_handoff!` server-side, which stops the bot and lets a
human agent take over. Flipping back to `pending` returns control to the bot.
"""
from __future__ import annotations

import hashlib
import hmac

import httpx

from .config import settings


def _url(path: str) -> str:
    base = settings.chatwoot_base_url.rstrip("/")
    return f"{base}/api/v1/accounts/{settings.chatwoot_account_id}{path}"


def _headers() -> dict[str, str]:
    return {"api_access_token": settings.chatwoot_api_access_token}


def verify_signature(raw_body: bytes, signature: str | None) -> bool:
    """Validate the HMAC-SHA256 signature Chatwoot sends with agent-bot webhooks."""
    if not settings.chatwoot_hmac_secret:
        return True  # not configured in local dev
    if not signature:
        return False
    expected = hmac.new(
        settings.chatwoot_hmac_secret.encode(), raw_body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


async def send_reply(conversation_id: int, content: str, private: bool = False) -> None:
    """Post an outgoing message (or a private internal note when private=True)."""
    async with httpx.AsyncClient(timeout=20) as client:
        await client.post(
            _url(f"/conversations/{conversation_id}/messages"),
            headers=_headers(),
            json={"content": content, "message_type": "outgoing", "private": private},
        )


async def handoff_to_human(conversation_id: int, summary: str) -> None:
    """Leave a private summary, then flip pending → open (triggers bot_handoff!)."""
    await send_reply(conversation_id, f"🤝 Handoff summary: {summary}", private=True)
    async with httpx.AsyncClient(timeout=20) as client:
        await client.post(
            _url(f"/conversations/{conversation_id}/toggle_status"),
            headers=_headers(),
            json={"status": "open"},
        )
