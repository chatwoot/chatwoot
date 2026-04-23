"""Conector Syonet – `POST /api/lead`.

Particularidades do PDF oficial:
- Auth: HTTP Basic.
- Content-Type esperado: `application/json` e resposta em ISO-8859-1.
- Body enviado também codificado em ISO-8859-1 (nomes com acento).
- `event.leadInfo.gclid` é case-sensitive.
- Retornos: 201 sucesso; 403 credencial/permissão; 412 regra de negócio (campo ausente ou inválido); 500 erro interno.
"""

from __future__ import annotations

import base64
import json
import logging
from typing import Any

import httpx
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential_jitter

from .config import Settings, get_settings
from .models.lead import NormalizedLead
from .models.syonet import (
    SyonetCustomer,
    SyonetEvent,
    SyonetLeadInfo,
    SyonetLeadRequest,
    SyonetLeadResponse,
    SyonetNegotiationRecord,
    SyonetPhone,
)

log = logging.getLogger(__name__)

RETRYABLE = (httpx.ConnectError, httpx.ReadTimeout, httpx.RemoteProtocolError)


class SyonetError(Exception):
    def __init__(self, message: str, *, status_code: int | None = None, body: str | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.body = body


class SyonetConnector:
    """Envia leads qualificados para a Syonet. Respeita ISO-8859-1 no corpo e na resposta."""

    def __init__(self, settings: Settings | None = None, client: httpx.Client | None = None) -> None:
        self.settings = settings or get_settings()
        self._owns_client = client is None
        self._client = client or httpx.Client(timeout=self.settings.syonet_timeout_seconds)

    # ---------- lifecycle ----------
    def close(self) -> None:
        if self._owns_client:
            self._client.close()

    def __enter__(self) -> SyonetConnector:
        return self

    def __exit__(self, *_: Any) -> None:
        self.close()

    # ---------- mapping ----------
    def build_request(self, lead: NormalizedLead, *, event_group: str = "VENDAS", event_type: str = "LEAD") -> SyonetLeadRequest:
        return SyonetLeadRequest(
            companyId=self.settings.syonet_company_id,
            customer=SyonetCustomer(
                externalId=lead.customer.external_id,
                firstName=lead.customer.first_name,
                lastName=lead.customer.last_name,
                documentNumber=lead.customer.document_number,
                phones=[SyonetPhone(number=p.number) for p in lead.customer.phones],
                emails=list(lead.customer.emails),
            ),
            event=SyonetEvent(
                eventGroup=event_group,
                eventType=event_type,
                leadInfo=SyonetLeadInfo(
                    gclid=lead.attribution.gclid,
                    fbclid=lead.attribution.fbclid,
                    utmSource=lead.attribution.utm_source,
                    utmMedium=lead.attribution.utm_medium,
                    utmCampaign=lead.attribution.utm_campaign,
                    utmTerm=lead.attribution.utm_term,
                    utmContent=lead.attribution.utm_content,
                ),
            ),
            negotiationRecord=SyonetNegotiationRecord(
                priceRange=lead.intent.price_range,
                observations=lead.intent.observations,
            ),
            additionalFields=_additional_fields(lead),
            daysToUpdateOpenEvent=self.settings.syonet_default_days_to_update_open_event,
        )

    # ---------- transport ----------
    @retry(
        reraise=True,
        stop=stop_after_attempt(3),
        wait=wait_exponential_jitter(initial=0.5, max=5),
        retry=retry_if_exception_type(RETRYABLE),
    )
    def send(self, lead: NormalizedLead) -> SyonetLeadResponse:
        payload = self.build_request(lead)
        # ISO-8859-1 para bater com o PDF oficial (campos com acento).
        raw = json.dumps(payload.model_dump(exclude_none=True), ensure_ascii=False).encode("iso-8859-1", errors="replace")

        headers = {
            "Authorization": _basic_auth(self.settings.syonet_user, self.settings.syonet_password),
            "Content-Type": "application/json; charset=ISO-8859-1",
            "Accept": "application/json",
        }

        url = f"{self.settings.syonet_base_url.rstrip('/')}/api/lead"
        log.info("syonet.post_lead", extra={"url": url, "lead_id": lead.lead_id, "tenant_id": lead.tenant_id})

        resp = self._client.post(url, content=raw, headers=headers)
        body_text = resp.content.decode("iso-8859-1", errors="replace")

        if resp.status_code >= 400:
            log.warning(
                "syonet.error",
                extra={"status": resp.status_code, "body": body_text[:500], "lead_id": lead.lead_id},
            )
            raise SyonetError(
                f"Syonet respondeu {resp.status_code}",
                status_code=resp.status_code,
                body=body_text,
            )

        try:
            parsed = json.loads(body_text) if body_text else {}
        except json.JSONDecodeError:
            parsed = {"message": body_text}

        return SyonetLeadResponse(
            leadId=parsed.get("leadId") or parsed.get("id"),
            status=parsed.get("status"),
            message=parsed.get("message"),
        )


def _basic_auth(user: str, password: str) -> str:
    token = base64.b64encode(f"{user}:{password}".encode()).decode("ascii")
    return f"Basic {token}"


def _additional_fields(lead: NormalizedLead) -> dict[str, str]:
    out: dict[str, str] = {}
    if lead.intent.brand:
        out["Brand"] = lead.intent.brand
    if lead.intent.model:
        out["Model"] = lead.intent.model
    return out
