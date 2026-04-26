"""Configuração central. Todas as variáveis vêm do ambiente (12-factor)."""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Runtime
    dexi_env: str = "local"
    dexi_mock_mode: bool = True
    log_level: str = "INFO"

    # HTTP
    http_host: str = "0.0.0.0"
    http_port: int = 8080

    # Redis / Celery
    redis_url: str = "redis://localhost:6379/0"

    # Postgres
    database_url: str = "postgresql+psycopg://dexi:dexi@localhost:5432/dexi"

    # Webhook HMAC secrets
    meta_app_secret: str = "change-me"
    google_shared_secret: str = "change-me"
    site_shared_secret: str = "change-me"
    whatsapp_app_secret: str = "change-me"

    # Syonet
    syonet_base_url: str = "https://mock.syonet.local"
    syonet_user: str = "integration"
    syonet_password: str = "integration"
    syonet_company_id: str = "000000"
    syonet_timeout_seconds: float = 10.0
    syonet_default_days_to_update_open_event: int = 30

    # LLM
    llm_provider_model: str = "gpt-4o-mini"
    llm_timeout_seconds: float = 15.0
    openai_api_key: str | None = None
    google_api_key: str | None = None
    azure_api_key: str | None = None
    anthropic_api_key: str | None = None

    # Dedup
    dedup_window_hours: int = Field(default=24, ge=1, le=720)

    # Chatwoot bridge — opt-in por cliente. Quando enabled, leads viram contato +
    # conversa no Chatwoot (Ponte A) e o webhook /webhooks/chatwoot/{tenant_id}
    # ouve mudanças de status pra atualizar o Syonet (Ponte B).
    chatwoot_enabled: bool = False
    chatwoot_base_url: str | None = None
    chatwoot_api_token: str | None = None
    chatwoot_account_id: int = 1
    chatwoot_default_inbox_id: int | None = None
    chatwoot_timeout_seconds: float = 10.0
    chatwoot_webhook_secret: str = "change-me"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
