"""Normalização de webhook Meta Lead Ads para o modelo canônico."""

from __future__ import annotations

import uuid
from typing import Any

from ..models.lead import LeadAttribution, LeadChannel, LeadCustomer, LeadIntent, LeadPhone, NormalizedLead


def normalize(body: dict[str, Any], tenant_id: str) -> NormalizedLead:
    """Recebe o envelope `{"object":"page","entry":[{...changes:[{value:{leadgen_id,...}}]}]}`.

    No MVP com `DEXI_MOCK_MODE=true` o chamador pode já entregar o lead expandido em `body["value"]`.
    Em produção, deve-se chamar a Graph API com o `leadgen_id` para obter `field_data`.
    """
    value = body.get("value") or _extract_first_value(body)
    field_data = {item["name"]: _first(item.get("values")) for item in value.get("field_data", [])}

    phone = field_data.get("phone_number") or field_data.get("phone")
    email = field_data.get("email")
    external_id = value.get("leadgen_id") or email or phone or str(uuid.uuid4())

    return NormalizedLead(
        lead_id=str(uuid.uuid4()),
        tenant_id=tenant_id,
        channel=LeadChannel.META,
        customer=LeadCustomer(
            external_id=str(external_id),
            first_name=field_data.get("first_name") or _split_full(field_data.get("full_name"))[0],
            last_name=field_data.get("last_name") or _split_full(field_data.get("full_name"))[1],
            phones=[LeadPhone(number=phone)] if phone else [],
            emails=[email] if email else [],
        ),
        attribution=LeadAttribution(
            fbclid=value.get("fbclid") or field_data.get("fbclid"),
            utm_source=field_data.get("utm_source") or "facebook",
            utm_medium=field_data.get("utm_medium") or "paid_social",
            utm_campaign=value.get("ad_id") or field_data.get("utm_campaign"),
        ),
        intent=LeadIntent(
            brand=field_data.get("brand"),
            model=field_data.get("vehicle") or field_data.get("model"),
            observations=field_data.get("comentario") or field_data.get("message"),
        ),
        raw_payload=body,
    )


def _first(values: list[str] | None) -> str | None:
    return values[0] if values else None


def _split_full(name: str | None) -> tuple[str | None, str | None]:
    if not name:
        return None, None
    parts = name.strip().split(maxsplit=1)
    return parts[0], parts[1] if len(parts) > 1 else None


def _extract_first_value(body: dict[str, Any]) -> dict[str, Any]:
    entries = body.get("entry") or []
    for entry in entries:
        for change in entry.get("changes", []):
            val = change.get("value")
            if val:
                return val
    return {}
