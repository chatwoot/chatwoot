"""Formulário genérico do site/LP da concessionária."""

from __future__ import annotations

import uuid
from typing import Any

from ..models.lead import LeadAttribution, LeadChannel, LeadCustomer, LeadIntent, LeadPhone, NormalizedLead


def normalize(body: dict[str, Any], tenant_id: str) -> NormalizedLead:
    email = body.get("email")
    phone = body.get("phone") or body.get("telefone") or body.get("whatsapp")
    first = body.get("first_name") or body.get("nome")
    last = body.get("last_name") or body.get("sobrenome")
    external_id = body.get("external_id") or email or phone or str(uuid.uuid4())

    return NormalizedLead(
        lead_id=str(uuid.uuid4()),
        tenant_id=tenant_id,
        channel=LeadChannel.SITE,
        customer=LeadCustomer(
            external_id=str(external_id),
            first_name=first,
            last_name=last,
            document_number=body.get("cpf") or body.get("cnpj"),
            phones=[LeadPhone(number=phone)] if phone else [],
            emails=[email] if email else [],
        ),
        attribution=LeadAttribution(
            gclid=body.get("gclid"),
            fbclid=body.get("fbclid"),
            utm_source=body.get("utm_source"),
            utm_medium=body.get("utm_medium"),
            utm_campaign=body.get("utm_campaign"),
            utm_term=body.get("utm_term"),
            utm_content=body.get("utm_content"),
        ),
        intent=LeadIntent(
            brand=body.get("brand") or body.get("marca"),
            model=body.get("model") or body.get("modelo"),
            price_range=body.get("price_range") or body.get("faixa_preco"),
            observations=body.get("mensagem") or body.get("message"),
        ),
        raw_payload=body,
    )
