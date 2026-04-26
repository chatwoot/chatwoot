"""Adapter pra webhooks de status do Chatwoot — Ponte B.

Eventos consumidos:
- `conversation_created`     → IGNORADO (já registramos no Syonet quando o lead chegou
                                pelo portal). Útil só pra disparar gatilho do N8N.
- `conversation_status_changed` com status=`open`     → evento "ATENDIMENTO" no Syonet.
- `conversation_status_changed` com status=`resolved` → evento "FINALIZADO" no Syonet.
- `assignee_changed`         → também conta como ATENDIMENTO (cobre o caso em que o
                                Chatwoot atribui sem mudar o status pra `open`).

Mapeamento → eventType no Syonet:
- ATENDIMENTO → eventGroup=VENDAS, eventType=ATENDIMENTO
- FINALIZADO  → eventGroup=VENDAS, eventType=FINALIZADO

A correlação com o lead original é feita via `conversation.id`, gravado em
`LeadAudit.chatwoot_conversation_id` na Ponte A.
"""

from __future__ import annotations

import logging
from enum import StrEnum
from typing import Any

from pydantic import BaseModel

log = logging.getLogger(__name__)


class StatusEvent(StrEnum):
    ATENDIMENTO = "ATENDIMENTO"
    FINALIZADO = "FINALIZADO"


class ChatwootStatusUpdate(BaseModel):
    tenant_id: str
    conversation_id: int
    event: StatusEvent
    raw: dict[str, Any]


def normalize(payload: dict[str, Any], tenant_id: str) -> ChatwootStatusUpdate | None:
    """Retorna `None` quando o evento não deve gerar update no Syonet."""
    event_type = payload.get("event")
    conversation = payload.get("conversation") or payload  # alguns webhooks vêm "achatados"
    conversation_id = conversation.get("id") or payload.get("id")
    if not conversation_id:
        return None

    status = (conversation.get("status") or payload.get("status") or "").lower()

    mapped: StatusEvent | None
    if event_type == "conversation_status_changed":
        mapped = _map_status(status)
    elif event_type == "assignee_changed":
        # Atribuição implica que algum agente assumiu — vale como ATENDIMENTO
        # mesmo se o status seguir `pending` por um instante.
        mapped = StatusEvent.ATENDIMENTO if conversation.get("assignee_id") or conversation.get("meta", {}).get("assignee") else None
    else:
        mapped = None

    if mapped is None:
        return None

    return ChatwootStatusUpdate(
        tenant_id=tenant_id,
        conversation_id=int(conversation_id),
        event=mapped,
        raw=payload,
    )


def _map_status(status: str) -> StatusEvent | None:
    if status == "open":
        return StatusEvent.ATENDIMENTO
    if status == "resolved":
        return StatusEvent.FINALIZADO
    return None
