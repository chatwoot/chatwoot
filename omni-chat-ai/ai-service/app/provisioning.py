"""Integration health checks and (later) auto-provisioning of Chatwoot resources.

Phase 1/2 ships ``test_connection`` for each integration so the admin panel can show live
green/red status and validate keys the moment they're entered. Chatwoot auto-wiring and LiteLLM
model registration build on these same clients in later phases.
"""
from __future__ import annotations

import httpx

from . import settings_service


async def _ai() -> tuple[bool, str]:
    if not settings_service.get("ai.api_key"):
        return False, "No API key set."
    # Validate via the LiteLLM gateway (OpenAI-compatible) with a 1-token completion.
    from .config import settings

    url = f"{settings.litellm_base_url.rstrip('/')}/v1/chat/completions"
    payload = {
        "model": settings_service.get("ai.model") or "claude-primary",
        "messages": [{"role": "user", "content": "ping"}],
        "max_tokens": 1,
    }
    headers = {"Authorization": f"Bearer {settings.litellm_master_key}"}
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(url, json=payload, headers=headers)
        if resp.status_code == 200:
            return True, "Model reachable."
        return False, f"Gateway returned {resp.status_code}: {resp.text[:140]}"
    except httpx.HTTPError as exc:
        return False, f"Gateway unreachable: {exc}"


async def _keycrm() -> tuple[bool, str]:
    key = settings_service.get("keycrm.api_key")
    if not key:
        return False, "No API key set."
    base = settings_service.get("keycrm.base_url").rstrip("/")
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(
                f"{base}/order", headers={"Authorization": f"Bearer {key}"},
                params={"limit": 1},
            )
        if resp.status_code == 200:
            return True, "Authenticated."
        return False, f"KeyCRM returned {resp.status_code}."
    except httpx.HTTPError as exc:
        return False, f"Unreachable: {exc}"


async def _chatwoot() -> tuple[bool, str]:
    token = settings_service.get("chatwoot.api_access_token")
    if not token:
        return False, "No access token set."
    base = settings_service.get("chatwoot.base_url").rstrip("/")
    account_id = settings_service.get("chatwoot.account_id")
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(
                f"{base}/api/v1/accounts/{account_id}",
                headers={"api_access_token": token},
            )
        if resp.status_code == 200:
            return True, "Connected."
        return False, f"Chatwoot returned {resp.status_code}."
    except httpx.HTTPError as exc:
        return False, f"Unreachable: {exc}"


async def _langfuse() -> tuple[bool, str]:
    if not settings_service.get("langfuse.public_key"):
        return False, "No keys set."
    host = settings_service.get("langfuse.host").rstrip("/")
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(f"{host}/api/public/health")
        if resp.status_code < 500:
            return True, "Reachable."
        return False, f"Langfuse returned {resp.status_code}."
    except httpx.HTTPError as exc:
        return False, f"Unreachable: {exc}"


async def _telegram() -> tuple[bool, str]:
    token = settings_service.get("channels.telegram_bot_token")
    if not token:
        return False, "No bot token set."
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(f"https://api.telegram.org/bot{token}/getMe")
        data = resp.json()
        if data.get("ok"):
            return True, f"@{data['result'].get('username', 'bot')}"
        return False, "Invalid bot token."
    except httpx.HTTPError as exc:
        return False, f"Unreachable: {exc}"


# Group key (as shown in the settings UI) → health check.
CHECKS = {
    "AI Provider": _ai,
    "KeyCRM": _keycrm,
    "Chatwoot": _chatwoot,
    "Observability": _langfuse,
    "Channels": _telegram,
}


async def test_connection(group: str) -> tuple[bool, str]:
    check = CHECKS.get(group)
    if check is None:
        return False, "Unknown integration."
    return await check()
