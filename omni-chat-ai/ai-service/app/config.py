"""Centralised configuration, loaded from environment (12-factor)."""
from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Chatwoot (Unified Chat Panel)
    chatwoot_base_url: str = "http://chatwoot:3000"
    chatwoot_api_access_token: str = ""
    chatwoot_account_id: int = 1
    chatwoot_hmac_secret: str = ""

    # Model gateway (provider-agnostic; Claude primary)
    litellm_base_url: str = "http://litellm:4000"
    litellm_master_key: str = "sk-omni-local"
    agent_model: str = "claude-primary"

    # KeyCRM
    keycrm_base_url: str = "https://openapi.keycrm.app/v1"
    keycrm_api_key: str = ""

    # Observability / eval
    langfuse_host: str = "http://langfuse:3000"
    langfuse_public_key: str = ""
    langfuse_secret_key: str = ""

    # RAG
    qdrant_url: str = "http://qdrant:6333"


settings = Settings()
