"""Integration health checks and (later) auto-provisioning of Chatwoot resources.

Phase 1/2 ships ``test_connection`` for each integration so the admin panel can show live
green/red status and validate keys the moment they're entered. Chatwoot auto-wiring and LiteLLM
model registration build on these same clients in later phases.
"""
from __future__ import annotations

import httpx

from . import settings_service
from .config import settings

# Provider id (ai.provider) → LiteLLM model prefix. Anthropic (Claude) is the default.
_PROVIDER_PREFIX = {"anthropic": "anthropic", "openai": "openai", "openrouter": "openrouter"}
# Fast alias target per provider (used by cost-sensitive agents and as the primary fallback).
_FAST_MODEL = {"anthropic": "claude-haiku-4-5"}


def _litellm_url(path: str) -> str:
    return f"{settings.litellm_base_url.rstrip('/')}{path}"


def _litellm_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {settings.litellm_master_key}"}


def _model_string(model: str) -> str:
    provider = settings_service.get("ai.provider") or "anthropic"
    prefix = _PROVIDER_PREFIX.get(provider, provider)
    return f"{prefix}/{model}"


async def register_llm_model() -> tuple[bool, str]:
    """Register/refresh the `claude-primary` and `claude-fast` aliases in LiteLLM with the
    provider key entered in the panel. Idempotent: existing aliases are removed first so a key
    change takes effect immediately, with no restart. Requires LiteLLM DB mode."""
    api_key = settings_service.get("ai.api_key")
    if not api_key:
        return False, "No API key set."
    provider = settings_service.get("ai.provider") or "anthropic"
    primary_model = settings_service.get("ai.model") or "claude-sonnet-4-6"
    fast_model = _FAST_MODEL.get(provider, primary_model)
    aliases = {"claude-primary": primary_model, "claude-fast": fast_model}

    try:
        async with httpx.AsyncClient(timeout=20) as client:
            existing = await client.get(_litellm_url("/model/info"), headers=_litellm_headers())
            for entry in (existing.json().get("data", []) if existing.status_code == 200 else []):
                name = entry.get("model_name")
                model_id = (entry.get("model_info") or {}).get("id")
                if name in aliases and model_id:
                    await client.post(
                        _litellm_url("/model/delete"),
                        headers=_litellm_headers(), json={"id": model_id},
                    )
            for alias, model in aliases.items():
                resp = await client.post(
                    _litellm_url("/model/new"),
                    headers=_litellm_headers(),
                    json={
                        "model_name": alias,
                        "litellm_params": {"model": _model_string(model), "api_key": api_key},
                    },
                )
                if resp.status_code >= 300:
                    return False, f"LiteLLM rejected {alias}: {resp.status_code} {resp.text[:120]}"
    except httpx.HTTPError as exc:
        return False, f"Gateway unreachable: {exc}"
    return True, "Model registered."


async def _ai() -> tuple[bool, str]:
    if not settings_service.get("ai.api_key"):
        return False, "No API key set."
    # Validate via the LiteLLM gateway (OpenAI-compatible) with a 1-token completion on the
    # `claude-primary` alias the agents actually use.
    url = _litellm_url("/v1/chat/completions")
    payload = {
        "model": "claude-primary",
        "messages": [{"role": "user", "content": "ping"}],
        "max_tokens": 1,
    }
    headers = _litellm_headers()
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
