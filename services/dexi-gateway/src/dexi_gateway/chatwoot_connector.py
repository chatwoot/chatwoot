"""Conector Chatwoot — Ponte A do gateway.

Pra cada lead aceito, garante um contato e cria uma conversa numa inbox do
Chatwoot. A criação da conversa dispara automaticamente o webhook do Chatwoot
(`conversation_created`), que é onde o N8N AgentBot escuta pra começar o fluxo
conversacional.

Endpoints usados (Chatwoot Application API v1):
- POST /api/v1/accounts/{account_id}/contacts/search       (find by external_id)
- POST /api/v1/accounts/{account_id}/contacts              (create)
- POST /api/v1/accounts/{account_id}/conversations         (create + first message)

Auth: header `api_access_token` com access_token de um agente/bot.
"""

from __future__ import annotations

import logging
from typing import Any

import httpx

from .config import Settings, get_settings
from .models.lead import NormalizedLead

log = logging.getLogger(__name__)


class ChatwootError(Exception):
    def __init__(self, message: str, *, status_code: int | None = None, body: str | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.body = body


class ChatwootConnector:
    """Cria contato + conversa no Chatwoot. Idempotente por `identifier`/external_id."""

    def __init__(self, settings: Settings | None = None, client: httpx.Client | None = None) -> None:
        self.settings = settings or get_settings()
        if not self.settings.chatwoot_base_url or not self.settings.chatwoot_api_token:
            raise ValueError("chatwoot_base_url and chatwoot_api_token are required when chatwoot_enabled=true")
        self._owns_client = client is None
        self._client = client or httpx.Client(timeout=self.settings.chatwoot_timeout_seconds)

    # ---------- lifecycle ----------
    def close(self) -> None:
        if self._owns_client:
            self._client.close()

    def __enter__(self) -> ChatwootConnector:
        return self

    def __exit__(self, *_: Any) -> None:
        self.close()

    # ---------- public API ----------
    def push_lead(self, lead: NormalizedLead, *, inbox_id: int | None = None) -> dict[str, int]:
        """Garante contato + abre conversa. Retorna {contact_id, conversation_id}."""
        target_inbox = inbox_id or self.settings.chatwoot_default_inbox_id
        if target_inbox is None:
            raise ValueError("inbox_id is required (set CHATWOOT_DEFAULT_INBOX_ID or pass inbox_id)")

        contact_id = self._find_or_create_contact(lead)
        conversation_id = self._create_conversation(contact_id, target_inbox, lead)
        return {"contact_id": contact_id, "conversation_id": conversation_id}

    # ---------- internals ----------
    def _find_or_create_contact(self, lead: NormalizedLead) -> int:
        existing = self._search_contact(lead.customer.external_id)
        if existing:
            return existing
        return self._create_contact(lead)

    def _search_contact(self, external_id: str) -> int | None:
        url = self._url(f"/contacts/search?q={external_id}&include=contact_inboxes")
        resp = self._client.get(url, headers=self._headers())
        if resp.status_code != 200:
            return None
        payload = resp.json() or {}
        for c in payload.get("payload", []) or []:
            if c.get("identifier") == external_id:
                return int(c["id"])
        return None

    def _create_contact(self, lead: NormalizedLead) -> int:
        body = {
            "identifier": lead.customer.external_id,
            "name": _full_name(lead),
            "email": lead.customer.emails[0] if lead.customer.emails else None,
            "phone_number": _e164(lead),
            "custom_attributes": {
                "lead_channel": lead.channel,
                "tenant_id": lead.tenant_id,
                "utm_source": lead.attribution.utm_source,
                "utm_campaign": lead.attribution.utm_campaign,
                "gclid": lead.attribution.gclid,
            },
        }
        resp = self._client.post(self._url("/contacts"), json=_strip_none(body), headers=self._headers())
        if resp.status_code not in (200, 201):
            raise ChatwootError(
                f"contacts create failed ({resp.status_code})",
                status_code=resp.status_code,
                body=resp.text,
            )
        payload = resp.json() or {}
        contact = (payload.get("payload") or {}).get("contact") or payload.get("payload") or {}
        contact_id = contact.get("id") or (payload.get("payload", {}).get("contact", {}) or {}).get("id")
        if not contact_id:
            raise ChatwootError("contact created but id missing", body=resp.text)
        return int(contact_id)

    def _create_conversation(self, contact_id: int, inbox_id: int, lead: NormalizedLead) -> int:
        body = {
            "source_id": lead.customer.external_id,
            "inbox_id": inbox_id,
            "contact_id": contact_id,
            "status": "pending",
            "additional_attributes": {
                "lead_id": lead.lead_id,
                "channel": lead.channel,
                "tenant_id": lead.tenant_id,
            },
            "custom_attributes": {
                "lead_brand": lead.intent.brand,
                "lead_model": lead.intent.model,
                "lead_score": lead.intent.score,
            },
            "message": {
                "content": _opening_message(lead),
                "message_type": "incoming",
            },
        }
        resp = self._client.post(self._url("/conversations"), json=_strip_none(body), headers=self._headers())
        if resp.status_code not in (200, 201):
            raise ChatwootError(
                f"conversations create failed ({resp.status_code})",
                status_code=resp.status_code,
                body=resp.text,
            )
        payload = resp.json() or {}
        conv_id = payload.get("id") or (payload.get("payload") or {}).get("id")
        if not conv_id:
            raise ChatwootError("conversation created but id missing", body=resp.text)
        return int(conv_id)

    def _url(self, path: str) -> str:
        base = self.settings.chatwoot_base_url.rstrip("/")
        return f"{base}/api/v1/accounts/{self.settings.chatwoot_account_id}{path}"

    def _headers(self) -> dict[str, str]:
        return {
            "api_access_token": self.settings.chatwoot_api_token,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }


def _full_name(lead: NormalizedLead) -> str:
    parts = [lead.customer.first_name, lead.customer.last_name]
    return " ".join(p for p in parts if p) or lead.customer.external_id


def _e164(lead: NormalizedLead) -> str | None:
    if not lead.customer.phones:
        return None
    raw = lead.customer.phones[0].number
    return raw if raw.startswith("+") else f"+{raw}"


def _opening_message(lead: NormalizedLead) -> str:
    lines = [
        f"Lead recebido via {lead.channel.upper()} ({lead.tenant_id}).",
    ]
    if lead.intent.brand or lead.intent.model:
        lines.append(f"Interesse: {lead.intent.brand or '?'} {lead.intent.model or ''}".strip())
    if lead.intent.observations:
        lines.append(f"Observações: {lead.intent.observations}")
    if lead.attribution.utm_source:
        lines.append(f"Origem: {lead.attribution.utm_source}/{lead.attribution.utm_campaign or '-'}")
    return "\n".join(lines)


def _strip_none(d: dict) -> dict:
    return {k: v for k, v in d.items() if v is not None}
