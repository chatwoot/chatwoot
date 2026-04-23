"""Normalização de WhatsApp Business Cloud API.

Um lead via WhatsApp é criado na primeira mensagem de um wa_id novo.
"""

from __future__ import annotations

import uuid
from typing import Any

from ..models.lead import LeadAttribution, LeadChannel, LeadCustomer, LeadIntent, LeadPhone, NormalizedLead


def normalize(body: dict[str, Any], tenant_id: str) -> NormalizedLead:
    value = _first_change_value(body)
    messages = value.get("messages") or []
    contacts = value.get("contacts") or []
    first_message = messages[0] if messages else {}
    first_contact = contacts[0] if contacts else {}

    wa_id = first_contact.get("wa_id") or first_message.get("from") or str(uuid.uuid4())
    profile_name = (first_contact.get("profile") or {}).get("name")
    text = (first_message.get("text") or {}).get("body")

    first, last = _split_full(profile_name)

    return NormalizedLead(
        lead_id=str(uuid.uuid4()),
        tenant_id=tenant_id,
        channel=LeadChannel.WHATSAPP,
        customer=LeadCustomer(
            external_id=str(wa_id),
            first_name=first,
            last_name=last,
            phones=[LeadPhone(number=wa_id)] if wa_id else [],
        ),
        attribution=LeadAttribution(utm_source="whatsapp", utm_medium="conversational"),
        intent=LeadIntent(observations=text),
        raw_payload=body,
    )


def _first_change_value(body: dict[str, Any]) -> dict[str, Any]:
    for entry in body.get("entry", []):
        for change in entry.get("changes", []):
            val = change.get("value")
            if val:
                return val
    return {}


def _split_full(name: str | None) -> tuple[str | None, str | None]:
    if not name:
        return None, None
    parts = name.strip().split(maxsplit=1)
    return parts[0], parts[1] if len(parts) > 1 else None
