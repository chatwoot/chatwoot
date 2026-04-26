"""Celery worker. Recebe leads normalizados, qualifica com IA, grava auditoria e envia ao Syonet."""

from __future__ import annotations

import logging

from celery import Celery
from sqlalchemy import select

from .adapters.chatwoot import ChatwootStatusUpdate, StatusEvent
from .chatwoot_connector import ChatwootConnector, ChatwootError
from .config import get_settings
from .db import LeadAudit, create_all, get_session
from .llm.qualifier import qualify
from .models.lead import NormalizedLead
from .syonet_connector import RETRYABLE as SYONET_TRANSPORT_ERRORS
from .syonet_connector import SyonetConnector, SyonetError

log = logging.getLogger(__name__)

_settings = get_settings()
celery_app = Celery("dexi_gateway", broker=_settings.redis_url, backend=_settings.redis_url)
celery_app.conf.task_acks_late = True
celery_app.conf.task_reject_on_worker_lost = True
celery_app.conf.task_default_retry_delay = 10
celery_app.conf.worker_max_tasks_per_child = 200

_schema_ready = False


def _ensure_schema() -> None:
    """Garante as tabelas uma única vez por processo worker.

    Em produção troque por Alembic — mas evitamos chamar `create_all` a cada task
    (pressão desnecessária no Postgres sob carga).
    """
    global _schema_ready
    if _schema_ready:
        return
    try:
        create_all()
        _schema_ready = True
    except Exception as exc:
        log.warning("db.create_all_failed", extra={"error": str(exc)})


@celery_app.task(name="dexi.process_lead", bind=True, max_retries=5)
def process_lead(self, lead_json: dict) -> dict:
    lead = NormalizedLead.model_validate(lead_json)
    log.info("lead.processing", extra={"lead_id": lead.lead_id, "tenant_id": lead.tenant_id, "channel": lead.channel})

    _ensure_schema()

    lead.intent = qualify(lead)

    with get_session() as sess:
        audit = LeadAudit(
            lead_id=lead.lead_id,
            tenant_id=lead.tenant_id,
            channel=lead.channel,
            external_id=lead.customer.external_id,
            status="qualified",
            payload=lead.model_dump(mode="json"),
        )
        sess.merge(audit)
        sess.commit()

    try:
        with SyonetConnector() as c:
            resp = c.send(lead)
    except SyonetError as exc:
        log.error("syonet.failed", extra={"lead_id": lead.lead_id, "status": exc.status_code, "body": exc.body})
        with get_session() as sess:
            row = sess.get(LeadAudit, lead.lead_id)
            if row is not None:
                row.status = "syonet_error"
                row.syonet_http_status = exc.status_code
                row.last_error = exc.body or str(exc)
                sess.commit()
        if exc.status_code in {500, 502, 503, 504}:
            raise self.retry(exc=exc, countdown=min(60 * (self.request.retries + 1), 600)) from exc
        return {"status": "syonet_error", "http_status": exc.status_code}
    except SYONET_TRANSPORT_ERRORS as exc:
        # Esgotou o retry do tenacity no connector (timeout / conexão recusada / protocolo).
        # Persiste status e deixa o Celery reagendar para não perder o lead.
        log.error("syonet.transport_failed", extra={"lead_id": lead.lead_id, "error": str(exc)})
        with get_session() as sess:
            row = sess.get(LeadAudit, lead.lead_id)
            if row is not None:
                row.status = "syonet_error"
                row.last_error = f"transport: {exc!r}"
                sess.commit()
        raise self.retry(exc=exc, countdown=min(60 * (self.request.retries + 1), 600)) from exc

    with get_session() as sess:
        row = sess.get(LeadAudit, lead.lead_id)
        if row is not None:
            row.status = "syonet_sent"
            row.syonet_lead_id = str(resp.leadId) if resp.leadId is not None else None
            row.syonet_http_status = 201
            sess.commit()

    chatwoot_ids = _push_to_chatwoot(lead)
    if chatwoot_ids:
        with get_session() as sess:
            row = sess.get(LeadAudit, lead.lead_id)
            if row is not None:
                row.chatwoot_contact_id = chatwoot_ids["contact_id"]
                row.chatwoot_conversation_id = chatwoot_ids["conversation_id"]
                sess.commit()

    log.info(
        "lead.sent",
        extra={
            "lead_id": lead.lead_id,
            "syonet_lead_id": resp.leadId,
            "chatwoot_conversation_id": (chatwoot_ids or {}).get("conversation_id"),
        },
    )
    return {
        "status": "sent",
        "syonet_lead_id": resp.leadId,
        "chatwoot_conversation_id": (chatwoot_ids or {}).get("conversation_id"),
    }


def _push_to_chatwoot(lead: NormalizedLead) -> dict[str, int] | None:
    """Ponte A — best-effort. Falha aqui não derruba o pipeline (Syonet já gravou).

    Cliente sem Chatwoot configurado simplesmente pula essa etapa.
    """
    settings = get_settings()
    if not settings.chatwoot_enabled:
        return None
    try:
        with ChatwootConnector(settings) as cw:
            return cw.push_lead(lead)
    except ChatwootError as exc:
        log.warning(
            "chatwoot.push_failed",
            extra={"lead_id": lead.lead_id, "status": exc.status_code, "body": (exc.body or "")[:300]},
        )
    except Exception as exc:  # transport / config / outras: não derruba o lead
        log.warning("chatwoot.push_error", extra={"lead_id": lead.lead_id, "error": repr(exc)})
    return None


@celery_app.task(name="dexi.update_lead_status", bind=True, max_retries=5)
def update_lead_status(self, status_json: dict) -> dict:
    """Ponte B — repassa mudança de status do Chatwoot pro Syonet.

    Hidrata o `NormalizedLead` original a partir do `payload` gravado em LeadAudit
    e reenvia pra Syonet com `eventType=ATENDIMENTO|FINALIZADO`. Syonet correlaciona
    pelo mesmo `customer.externalId` (`daysToUpdateOpenEvent` permite update do
    evento aberto).
    """
    update = ChatwootStatusUpdate.model_validate(status_json)

    with get_session() as sess:
        row = sess.scalars(
            select(LeadAudit).where(
                LeadAudit.chatwoot_conversation_id == update.conversation_id,
                LeadAudit.tenant_id == update.tenant_id,
            ).limit(1)
        ).first()
        payload = row.payload if row else None

    if not payload:
        log.warning(
            "chatwoot.status_unknown_conversation",
            extra={"conversation_id": update.conversation_id, "tenant_id": update.tenant_id},
        )
        return {"status": "ignored", "reason": "unknown_conversation"}

    lead = NormalizedLead.model_validate(payload)
    event_type = "ATENDIMENTO" if update.event == StatusEvent.ATENDIMENTO else "FINALIZADO"

    try:
        with SyonetConnector() as c:
            c.send(lead, event_group="VENDAS", event_type=event_type)
    except SyonetError as exc:
        log.error(
            "syonet.status_update_failed",
            extra={"lead_id": lead.lead_id, "event": event_type, "status": exc.status_code},
        )
        if exc.status_code in {500, 502, 503, 504}:
            raise self.retry(exc=exc, countdown=min(60 * (self.request.retries + 1), 600)) from exc
        return {"status": "syonet_error", "http_status": exc.status_code}
    except SYONET_TRANSPORT_ERRORS as exc:
        log.error("syonet.status_update_transport_failed", extra={"lead_id": lead.lead_id, "error": repr(exc)})
        raise self.retry(exc=exc, countdown=min(60 * (self.request.retries + 1), 600)) from exc

    with get_session() as sess:
        row = sess.get(LeadAudit, lead.lead_id)
        if row is not None:
            row.status = f"chatwoot_{update.event.value.lower()}"
            sess.commit()

    log.info(
        "chatwoot.status_forwarded",
        extra={"lead_id": lead.lead_id, "event": event_type, "conversation_id": update.conversation_id},
    )
    return {"status": "forwarded", "event": event_type, "lead_id": lead.lead_id}
