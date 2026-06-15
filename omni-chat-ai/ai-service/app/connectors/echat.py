"""E-Chat.tech bridge for personal Telegram / Viber → Chatwoot API channel.

Status: ready-but-needs-your-account. The Chatwoot API-channel provisioning and the inbound→
Chatwoot relay are implemented; the two E-Chat-specific functions (``_parse_inbound`` and
``send_to_echat``) are the adapter boundary — fill them in with your E-Chat account's webhook
payload shape and send endpoint. Until an E-Chat account is paired, this stays dormant.
"""
from __future__ import annotations

import httpx

from .. import channels, settings_service
from ..config import settings


async def ensure_inbox() -> tuple[bool, str]:
    """Create the Chatwoot API-channel inbox that E-Chat messages land in, and connect the bot."""
    ok, msg = await channels.ensure_agent_bot()
    if not ok:
        return ok, msg
    if settings_service.get("echat.inbox_identifier"):
        return True, "E-Chat inbox already created."
    webhook_url = f"{settings.public_base_url.rstrip('/')}/connectors/echat/outbound"
    try:
        data = await channels._create_inbox(
            "E-Chat (personal)", {"type": "api", "webhook_url": webhook_url}
        )
        await settings_service.set_value("echat.inbox_identifier", data.get("inbox_identifier", ""))
        await channels._connect_bot(data["id"])
        return True, "E-Chat inbox created and connected."
    except httpx.HTTPError as exc:
        return False, f"Failed: {exc}"


def _parse_inbound(payload: dict) -> tuple[str, str, str] | None:
    """ADAPTER BOUNDARY — map an E-Chat webhook payload to (source_id, name, text).

    Return None to ignore the event. Fill this in against your E-Chat account's webhook shape.
    """
    source_id = str(payload.get("from") or payload.get("sender") or "")
    text = payload.get("text") or payload.get("message") or ""
    name = payload.get("name") or source_id
    if not source_id or not text:
        return None
    return source_id, name, text


async def send_to_echat(source_id: str, text: str) -> None:
    """ADAPTER BOUNDARY — deliver an agent reply back to the customer via E-Chat's send API."""
    api_key = settings_service.get("echat.api_key")
    base = settings_service.get("echat.base_url")
    if not api_key or not base:
        return
    async with httpx.AsyncClient(timeout=20) as client:
        await client.post(
            f"{base.rstrip('/')}/messages",
            headers={"Authorization": f"Bearer {api_key}"},
            json={"to": source_id, "text": text},
        )


async def handle_inbound(payload: dict) -> None:
    """Relay an inbound E-Chat message into the Chatwoot API-channel inbox."""
    parsed = _parse_inbound(payload)
    identifier = settings_service.get("echat.inbox_identifier")
    if parsed is None or not identifier:
        return
    source_id, name, text = parsed
    base = settings_service.get("chatwoot.base_url").rstrip("/")
    pub = f"{base}/public/api/v1/inboxes/{identifier}"
    async with httpx.AsyncClient(timeout=20) as client:
        contact = await client.post(f"{pub}/contacts", json={"identifier": source_id, "name": name})
        contact.raise_for_status()
        contact_source_id = contact.json()["source_id"]
        conv = await client.post(f"{pub}/contacts/{contact_source_id}/conversations", json={})
        conv.raise_for_status()
        display_id = conv.json()["id"]
        await client.post(
            f"{pub}/contacts/{contact_source_id}/conversations/{display_id}/messages",
            json={"content": text},
        )
