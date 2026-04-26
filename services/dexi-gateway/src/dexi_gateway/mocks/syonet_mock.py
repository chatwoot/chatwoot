"""Mock de um tenant Syonet. Responde `POST /api/lead` em ISO-8859-1 como o PDF oficial."""

from __future__ import annotations

import base64
import itertools
import json
import logging

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response

log = logging.getLogger(__name__)
app = FastAPI(title="Syonet Mock")

_counter = itertools.count(1)
_VALID_CREDENTIALS = {("integration", "integration")}


@app.post("/api/lead")
async def post_lead(request: Request) -> Response:
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("basic "):
        raise HTTPException(status_code=403, detail="missing basic auth")
    try:
        decoded = base64.b64decode(auth.split(None, 1)[1]).decode()
        user, _, password = decoded.partition(":")
    except Exception as exc:
        raise HTTPException(status_code=403, detail="invalid basic auth") from exc
    if (user, password) not in _VALID_CREDENTIALS:
        raise HTTPException(status_code=403, detail="unauthorized")

    raw = await request.body()
    try:
        payload = json.loads(raw.decode("iso-8859-1"))
    except Exception as exc:
        return _iso_response({"status": "error", "message": f"invalid body: {exc}"}, status=412)

    if not payload.get("companyId"):
        return _iso_response({"status": "error", "message": "companyId is required"}, status=412)
    if not payload.get("customer"):
        return _iso_response({"status": "error", "message": "customer is required"}, status=412)
    event = payload.get("event") or {}
    if not event.get("eventGroup") or not event.get("eventType"):
        return _iso_response({"status": "error", "message": "event.eventGroup/eventType required"}, status=412)

    lead_id = next(_counter)
    log.info("syonet_mock.accepted", extra={"leadId": lead_id})
    return _iso_response({"status": "ok", "leadId": lead_id, "message": "Lead recebido com sucesso"}, status=201)


def _iso_response(data: dict, status: int) -> Response:
    body = json.dumps(data, ensure_ascii=False).encode("iso-8859-1")
    return Response(content=body, status_code=status, media_type="application/json; charset=ISO-8859-1")
