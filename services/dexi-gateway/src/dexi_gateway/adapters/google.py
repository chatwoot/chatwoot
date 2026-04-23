"""Normalização de webhook Google Lead Form Extensions."""

from __future__ import annotations

import uuid
from typing import Any

from ..models.lead import LeadAttribution, LeadChannel, LeadCustomer, LeadIntent, LeadPhone, NormalizedLead


def normalize(body: dict[str, Any], tenant_id: str) -> NormalizedLead:
    """Formato Google: `{"lead_id", "form_id", "user_column_data":[{column_id,string_value}], "gcl_id"}`."""
    columns = {c["column_id"]: c.get("string_value") for c in body.get("user_column_data", [])}

    email = columns.get("EMAIL") or columns.get("email")
    phone = columns.get("PHONE_NUMBER") or columns.get("phone_number")
    full_name = columns.get("FULL_NAME") or columns.get("full_name")
    external_id = body.get("lead_id") or email or phone or str(uuid.uuid4())

    return NormalizedLead(
        lead_id=str(uuid.uuid4()),
        tenant_id=tenant_id,
        channel=LeadChannel.GOOGLE,
        customer=LeadCustomer(
            external_id=str(external_id),
            first_name=_split_full(full_name)[0],
            last_name=_split_full(full_name)[1],
            phones=[LeadPhone(number=phone)] if phone else [],
            emails=[email] if email else [],
        ),
        attribution=LeadAttribution(
            gclid=body.get("gcl_id") or body.get("gclid"),
            utm_source=columns.get("utm_source") or "google",
            utm_medium=columns.get("utm_medium") or "cpc",
            utm_campaign=columns.get("utm_campaign") or body.get("campaign_id"),
        ),
        intent=LeadIntent(
            brand=columns.get("brand"),
            model=columns.get("vehicle") or columns.get("model"),
            observations=columns.get("comments") or columns.get("message"),
        ),
        raw_payload=body,
    )


def _split_full(name: str | None) -> tuple[str | None, str | None]:
    if not name:
        return None, None
    parts = name.strip().split(maxsplit=1)
    return parts[0], parts[1] if len(parts) > 1 else None
