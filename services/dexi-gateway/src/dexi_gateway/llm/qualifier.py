"""Qualificador LLM multi-provider via LiteLLM. Determinístico em modo mock."""

from __future__ import annotations

import json
import logging
import re
from typing import Any

from ..config import get_settings
from ..models.lead import LeadIntent, NormalizedLead

log = logging.getLogger(__name__)

_QUALIFIER_PROMPT = """Você é Iza, agente de qualificação de leads automotivos da Dexi.
Dado o lead abaixo, devolva SOMENTE um JSON com os campos:
- brand (string | null)
- model (string | null)
- price_range (string | null)   # faixa aproximada, ex: "80-110k"
- observations (string)         # 1 frase neutra resumindo a intenção
- score (number 0..1)           # intenção de compra

LEAD:
{lead_json}
"""

_BRAND_HINTS = {
    "toyota": "Toyota", "hilux": "Toyota", "corolla": "Toyota",
    "fiat": "Fiat", "toro": "Fiat", "argo": "Fiat",
    "jeep": "Jeep", "compass": "Jeep", "renegade": "Jeep",
    "volkswagen": "Volkswagen", "vw": "Volkswagen", "nivus": "Volkswagen",
    "chevrolet": "Chevrolet", "gm": "Chevrolet", "onix": "Chevrolet", "tracker": "Chevrolet",
    "ford": "Ford", "ranger": "Ford",
    "honda": "Honda", "hrv": "Honda", "civic": "Honda",
    "hyundai": "Hyundai", "creta": "Hyundai", "hb20": "Hyundai",
}


def qualify(lead: NormalizedLead) -> LeadIntent:
    """Preenche brand/model/score do lead. Usa mock determinístico se `dexi_mock_mode=true`."""
    settings = get_settings()
    if settings.dexi_mock_mode:
        return _qualify_mock(lead)
    try:
        return _qualify_llm(lead)
    except Exception as exc:  # LLM fora do ar não pode derrubar o pipeline
        log.warning("llm.qualify_failed_falling_back", extra={"lead_id": lead.lead_id, "error": str(exc)})
        return _qualify_mock(lead)


# ------------ mock ------------
def _qualify_mock(lead: NormalizedLead) -> LeadIntent:
    hay = " ".join(
        filter(
            None,
            [
                (lead.customer.first_name or ""),
                (lead.customer.last_name or ""),
                (lead.intent.observations or ""),
                json.dumps(lead.raw_payload, ensure_ascii=False),
            ],
        )
    ).lower()

    brand = next((v for k, v in _BRAND_HINTS.items() if re.search(rf"\b{k}\b", hay)), lead.intent.brand)
    model = lead.intent.model
    if not model:
        m = re.search(r"\b(toro|corolla|hilux|compass|tracker|creta|hb20|nivus|onix|ranger|civic|hrv|renegade|argo)\b", hay)
        model = m.group(1).title() if m else None

    score = 0.6
    if lead.attribution.gclid or lead.attribution.fbclid:
        score = 0.75
    if brand and model:
        score = min(1.0, score + 0.15)

    return LeadIntent(
        brand=brand,
        model=model,
        price_range=lead.intent.price_range,
        observations=lead.intent.observations or "Lead recebido via canal digital; qualificação automática (mock).",
        score=score,
    )


# ------------ real ------------
def _qualify_llm(lead: NormalizedLead) -> LeadIntent:
    import litellm  # import tardio para não exigir a dep no import do pacote

    settings = get_settings()
    payload = lead.model_dump(mode="json", exclude={"raw_payload"})
    prompt = _QUALIFIER_PROMPT.format(lead_json=json.dumps(payload, ensure_ascii=False))

    resp = litellm.completion(
        model=settings.llm_provider_model,
        messages=[{"role": "user", "content": prompt}],
        timeout=settings.llm_timeout_seconds,
        response_format={"type": "json_object"},
    )
    content = resp["choices"][0]["message"]["content"]
    data: dict[str, Any] = json.loads(content)
    return LeadIntent(
        brand=data.get("brand"),
        model=data.get("model"),
        price_range=data.get("price_range"),
        observations=data.get("observations") or "",
        score=float(data.get("score") or 0.5),
    )
