"""Celery worker. Recebe leads normalizados, qualifica com IA, grava auditoria e envia ao Syonet."""

from __future__ import annotations

import logging

from celery import Celery

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


@celery_app.task(name="dexi.process_lead", bind=True, max_retries=5)
def process_lead(self, lead_json: dict) -> dict:
    lead = NormalizedLead.model_validate(lead_json)
    log.info("lead.processing", extra={"lead_id": lead.lead_id, "tenant_id": lead.tenant_id, "channel": lead.channel})

    try:
        create_all()  # garantido em dev; em prod use alembic
    except Exception as exc:  # DB down não pode derrubar; log e segue
        log.warning("db.create_all_failed", extra={"error": str(exc)})

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

    log.info("lead.sent", extra={"lead_id": lead.lead_id, "syonet_lead_id": resp.leadId})
    return {"status": "sent", "syonet_lead_id": resp.leadId}
