"""API FastAPI – webhooks de entrada."""

from __future__ import annotations

import logging

from fastapi import FastAPI, Header, HTTPException, Request, status
from fastapi.responses import JSONResponse

from .adapters import google as google_adapter
from .adapters import meta as meta_adapter
from .adapters import site as site_adapter
from .adapters import whatsapp as whatsapp_adapter
from .config import get_settings
from .dedup import seen_recently
from .hmac_utils import verify_sha256
from .logging_conf import configure_logging
from .models.lead import NormalizedLead
from .worker import process_lead

log = logging.getLogger(__name__)

configure_logging(get_settings().log_level)
app = FastAPI(title="Dexi Gateway", version="0.1.0")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok", "env": get_settings().dexi_env}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    return {"status": "ready"}


# ---------- Meta Lead Ads ----------
@app.get("/webhooks/meta")
def meta_verify(hub_mode: str | None = None, hub_challenge: str | None = None, hub_verify_token: str | None = None) -> JSONResponse:
    """Handshake de verificação do Facebook Webhooks."""
    _ = hub_verify_token  # reserva: validar contra META_VERIFY_TOKEN quando for configurado
    if hub_mode == "subscribe" and hub_challenge:
        return JSONResponse(content=int(hub_challenge) if hub_challenge.isdigit() else hub_challenge)
    raise HTTPException(status_code=400, detail="invalid verify request")


@app.post("/webhooks/meta/{tenant_id}", status_code=status.HTTP_202_ACCEPTED)
async def meta_webhook(tenant_id: str, request: Request, x_hub_signature_256: str | None = Header(default=None)) -> dict:
    body = await request.body()
    settings = get_settings()
    if not settings.dexi_mock_mode and not verify_sha256(settings.meta_app_secret, body, x_hub_signature_256):
        raise HTTPException(status_code=401, detail="invalid HMAC")
    payload = await _json(request, body)
    lead = meta_adapter.normalize(payload, tenant_id)
    return _enqueue(lead)


# ---------- Google Lead Form ----------
@app.post("/webhooks/google/{tenant_id}", status_code=status.HTTP_202_ACCEPTED)
async def google_webhook(tenant_id: str, request: Request, x_signature: str | None = Header(default=None)) -> dict:
    body = await request.body()
    settings = get_settings()
    if not settings.dexi_mock_mode and not verify_sha256(settings.google_shared_secret, body, x_signature):
        raise HTTPException(status_code=401, detail="invalid HMAC")
    payload = await _json(request, body)
    lead = google_adapter.normalize(payload, tenant_id)
    return _enqueue(lead)


# ---------- Site / LP ----------
@app.post("/webhooks/site/{tenant_id}", status_code=status.HTTP_202_ACCEPTED)
async def site_webhook(tenant_id: str, request: Request, x_signature: str | None = Header(default=None)) -> dict:
    body = await request.body()
    settings = get_settings()
    if not settings.dexi_mock_mode and not verify_sha256(settings.site_shared_secret, body, x_signature):
        raise HTTPException(status_code=401, detail="invalid HMAC")
    payload = await _json(request, body)
    lead = site_adapter.normalize(payload, tenant_id)
    return _enqueue(lead)


# ---------- WhatsApp Business Cloud ----------
@app.post("/webhooks/whatsapp/{tenant_id}", status_code=status.HTTP_202_ACCEPTED)
async def whatsapp_webhook(tenant_id: str, request: Request, x_hub_signature_256: str | None = Header(default=None)) -> dict:
    body = await request.body()
    settings = get_settings()
    if not settings.dexi_mock_mode and not verify_sha256(settings.whatsapp_app_secret, body, x_hub_signature_256):
        raise HTTPException(status_code=401, detail="invalid HMAC")
    payload = await _json(request, body)
    lead = whatsapp_adapter.normalize(payload, tenant_id)
    return _enqueue(lead)


# ---------- helpers ----------
async def _json(request: Request, body: bytes) -> dict:
    if not body:
        return {}
    try:
        return await request.json()
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"invalid JSON: {exc}") from exc


def _enqueue(lead: NormalizedLead) -> dict:
    if seen_recently(lead.tenant_id, lead.customer.external_id):
        log.info("lead.dedup_suppressed", extra={"tenant_id": lead.tenant_id, "external_id": lead.customer.external_id})
        return {"status": "deduplicated", "lead_id": lead.lead_id}

    process_lead.delay(lead.model_dump(mode="json"))
    log.info("lead.enqueued", extra={"lead_id": lead.lead_id, "tenant_id": lead.tenant_id, "channel": lead.channel})
    return {"status": "accepted", "lead_id": lead.lead_id}
