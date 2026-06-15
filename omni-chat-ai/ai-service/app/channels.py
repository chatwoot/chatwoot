"""Chatwoot channel auto-provisioning (verified against Chatwoot source).

From the admin panel we create the agent bot, a web-widget inbox, and a Telegram inbox, and
connect the bot to each — so the operator never clicks through Chatwoot's settings. All calls
use the admin access token bootstrapped at deploy time (``chatwoot.api_access_token``).

Note: agent-bot webhooks are delivered unsigned (no X-Chatwoot-Signature), so the AI service
accepts them when no HMAC secret is configured — see chatwoot.verify_signature.
"""
from __future__ import annotations

import httpx

from . import settings_service
from .config import settings


def _base() -> str:
    return settings_service.get("chatwoot.base_url").rstrip("/")


def _acct_url(path: str) -> str:
    account_id = settings_service.get("chatwoot.account_id")
    return f"{_base()}/api/v1/accounts/{account_id}{path}"


def _headers() -> dict[str, str]:
    return {"api_access_token": settings_service.get("chatwoot.api_access_token")}


def _webhook_url() -> str:
    return f"{settings.public_base_url.rstrip('/')}/webhooks/chatwoot"


async def ensure_agent_bot() -> tuple[bool, str]:
    """Create the AI agent bot (idempotent on our side) pointing at our webhook, and remember
    its id. Returns (ok, message)."""
    if not settings_service.get("chatwoot.api_access_token"):
        return False, "Set the Chatwoot admin access token first."
    if settings_service.get("chatwoot.agent_bot_id"):
        return True, "Agent bot already created."
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(
                _acct_url("/agent_bots"),
                headers=_headers(),
                json={
                    "name": "Omni-Chat-AI",
                    "description": "AI agents for support, consultation, warranty and sales.",
                    "outgoing_url": _webhook_url(),
                    "bot_type": "webhook",
                },
            )
        if resp.status_code >= 300:
            return False, f"Chatwoot returned {resp.status_code}: {resp.text[:140]}"
        data = resp.json()
        await settings_service.set_value("chatwoot.agent_bot_id", str(data["id"]))
        return True, "Agent bot created."
    except httpx.HTTPError as exc:
        return False, f"Unreachable: {exc}"


async def _create_inbox(name: str, channel: dict) -> dict:
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            _acct_url("/inboxes"), headers=_headers(), json={"name": name, "channel": channel}
        )
    resp.raise_for_status()
    return resp.json()


async def _connect_bot(inbox_id: int) -> None:
    bot_id = settings_service.get("chatwoot.agent_bot_id")
    if not bot_id:
        return
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.post(
            _acct_url(f"/inboxes/{inbox_id}/set_agent_bot"),
            headers=_headers(), json={"agent_bot": int(bot_id)},
        )
        resp.raise_for_status()


async def ensure_web_widget(website_url: str) -> tuple[bool, str]:
    """Create a website-widget inbox, connect the bot, and store the embed token/script."""
    ok, msg = await ensure_agent_bot()
    if not ok:
        return ok, msg
    if settings_service.get("chatwoot.web_widget_inbox_id"):
        return True, "Web widget already created."
    try:
        data = await _create_inbox(
            "Website", {"type": "web_widget", "website_url": website_url}
        )
        inbox_id = data["id"]
        await settings_service.set_value("chatwoot.web_widget_inbox_id", str(inbox_id))
        await settings_service.set_value("chatwoot.website_token", data.get("website_token", ""))
        await settings_service.set_value("chatwoot.web_widget_script", data.get("web_widget_script", ""))
        await _connect_bot(inbox_id)
        return True, "Web widget created and connected."
    except httpx.HTTPError as exc:
        return False, f"Failed: {exc}"


async def ensure_telegram() -> tuple[bool, str]:
    """Create a Telegram inbox from the bot token in settings and connect the bot. Chatwoot
    auto-registers the Telegram webhook on creation."""
    token = settings_service.get("channels.telegram_bot_token")
    if not token:
        return False, "Enter a Telegram bot token in Settings first."
    ok, msg = await ensure_agent_bot()
    if not ok:
        return ok, msg
    if settings_service.get("chatwoot.telegram_inbox_id"):
        return True, "Telegram already connected."
    try:
        data = await _create_inbox("Telegram", {"type": "telegram", "bot_token": token})
        inbox_id = data["id"]
        await settings_service.set_value("chatwoot.telegram_inbox_id", str(inbox_id))
        await _connect_bot(inbox_id)
        return True, f"Telegram connected ({data.get('bot_name', 'bot')})."
    except httpx.HTTPError as exc:
        return False, f"Failed: {exc}"
