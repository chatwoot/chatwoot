"""Runtime settings store — the single source of truth for user-entered configuration.

API keys and connection details are entered in the admin panel and persisted (encrypted) in
Postgres. To keep the many existing synchronous call sites simple, values are mirrored into an
in-memory cache that is refreshed from the DB at startup and after every write. ``get`` is a
plain synchronous lookup: cache → environment fallback (``config.settings``) → registry default.

This means the service still boots and tests still pass with no database and no panel input —
the ``.env``/defaults simply act as the fallback layer.
"""
from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select

from .config import settings as env_settings
from .crypto import open_secret, seal


@dataclass(frozen=True)
class SettingSpec:
    key: str
    label: str
    group: str
    secret: bool = False
    default: str = ""
    env_attr: str | None = None  # attribute on config.Settings used as fallback
    help: str = ""


# Grouped registry rendered by the admin panel. Order here is the order shown in the UI.
REGISTRY: tuple[SettingSpec, ...] = (
    # --- AI provider (key is pushed into LiteLLM on save) ---
    SettingSpec("ai.provider", "Provider", "AI Provider", default="anthropic",
                help="Model provider behind the LiteLLM gateway. Anthropic (Claude) by default."),
    SettingSpec("ai.model", "Model", "AI Provider", default="claude-sonnet-4-6",
                help="Underlying model id registered as the 'claude-primary' alias."),
    SettingSpec("ai.api_key", "API key", "AI Provider", secret=True,
                help="Anthropic API key. Stored encrypted; registered with LiteLLM on save."),
    # --- Chatwoot ---
    SettingSpec("chatwoot.base_url", "Base URL", "Chatwoot", default="http://chatwoot:3000",
                env_attr="chatwoot_base_url"),
    SettingSpec("chatwoot.account_id", "Account ID", "Chatwoot", default="1",
                env_attr="chatwoot_account_id"),
    SettingSpec("chatwoot.api_access_token", "Access token", "Chatwoot", secret=True,
                env_attr="chatwoot_api_access_token"),
    SettingSpec("chatwoot.hmac_secret", "Webhook HMAC secret", "Chatwoot", secret=True,
                env_attr="chatwoot_hmac_secret"),
    # --- KeyCRM ---
    SettingSpec("keycrm.base_url", "Base URL", "KeyCRM",
                default="https://openapi.keycrm.app/v1", env_attr="keycrm_base_url"),
    SettingSpec("keycrm.api_key", "API key", "KeyCRM", secret=True, env_attr="keycrm_api_key"),
    # --- Observability ---
    SettingSpec("langfuse.host", "Host", "Observability", default="http://langfuse:3000",
                env_attr="langfuse_host"),
    SettingSpec("langfuse.public_key", "Public key", "Observability",
                env_attr="langfuse_public_key"),
    SettingSpec("langfuse.secret_key", "Secret key", "Observability", secret=True,
                env_attr="langfuse_secret_key"),
    # --- Channels ---
    SettingSpec("channels.telegram_bot_token", "Telegram bot token", "Channels", secret=True,
                help="From @BotFather. Saving provisions a Telegram inbox in Chatwoot."),
    SettingSpec("echat.base_url", "E-Chat base URL", "Channels",
                default="https://api.e-chat.tech", env_attr="echat_base_url",
                help="E-Chat.tech bridge for personal Telegram/Viber (needs an E-Chat account)."),
    SettingSpec("echat.api_key", "E-Chat API key", "Channels", secret=True,
                env_attr="echat_api_key"),
    SettingSpec("echat.webhook_secret", "E-Chat webhook secret", "Channels", secret=True,
                env_attr="echat_webhook_secret",
                help="Shared secret E-Chat must send (?token= or X-Connector-Secret) on inbound."),
)

_SPEC_BY_KEY: dict[str, SettingSpec] = {s.key: s for s in REGISTRY}
GROUPS: tuple[str, ...] = tuple(dict.fromkeys(s.group for s in REGISTRY))

# Runtime cache of values that were explicitly saved in the panel (decrypted).
_cache: dict[str, str] = {}


def _env_fallback(spec: SettingSpec) -> str:
    if spec.env_attr and hasattr(env_settings, spec.env_attr):
        return str(getattr(env_settings, spec.env_attr))
    return spec.default


def get(key: str) -> str:
    """Synchronous lookup: saved value → environment fallback → registry default."""
    if key in _cache:
        return _cache[key]
    spec = _SPEC_BY_KEY.get(key)
    return _env_fallback(spec) if spec else ""


def is_configured(key: str) -> bool:
    return bool(get(key))


async def refresh() -> None:
    """Reload the cache from the database. Safe to call when the DB is unavailable (no-op)."""
    from .db import SessionLocal
    from .models_db import AppSetting

    try:
        async with SessionLocal() as session:
            rows = (await session.execute(select(AppSetting))).scalars().all()
    except Exception:  # DB not reachable (e.g. local tests) — keep env/default fallbacks
        return

    fresh: dict[str, str] = {}
    for row in rows:
        if row.is_secret and row.encrypted_value is not None:
            fresh[row.key] = open_secret(row.encrypted_value)
        elif row.value is not None:
            fresh[row.key] = row.value
    _cache.clear()
    _cache.update(fresh)


async def set_value(key: str, value: str) -> None:
    """Persist a value (encrypting secrets) and update the in-memory cache."""
    from .db import SessionLocal
    from .models_db import AppSetting

    spec = _SPEC_BY_KEY.get(key)
    secret = bool(spec and spec.secret)

    async with SessionLocal() as session:
        row = await session.get(AppSetting, key)
        if row is None:
            row = AppSetting(key=key, is_secret=secret)
            session.add(row)
        row.is_secret = secret
        if secret:
            row.encrypted_value = seal(value)
            row.value = None
        else:
            row.value = value
            row.encrypted_value = None
        await session.commit()

    _cache[key] = value
