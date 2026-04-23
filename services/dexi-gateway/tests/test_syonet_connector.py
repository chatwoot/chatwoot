from __future__ import annotations

import json

import httpx
import pytest
import respx

from dexi_gateway.config import Settings
from dexi_gateway.models.lead import (
    LeadAttribution,
    LeadChannel,
    LeadCustomer,
    LeadIntent,
    LeadPhone,
    NormalizedLead,
)
from dexi_gateway.syonet_connector import SyonetConnector, SyonetError


def _sample_lead() -> NormalizedLead:
    return NormalizedLead(
        lead_id="l-1",
        tenant_id="t1",
        channel=LeadChannel.META,
        customer=LeadCustomer(
            external_id="cpf-123",
            first_name="Lorrayne",
            last_name="Paraíso",
            phones=[LeadPhone(number="+5541999999999")],
            emails=["l@example.com"],
        ),
        attribution=LeadAttribution(gclid="g1", fbclid="f1", utm_source="facebook"),
        intent=LeadIntent(brand="Fiat", model="Toro", observations="Interesse em Toro"),
    )


def _settings(url: str) -> Settings:
    return Settings(
        syonet_base_url=url,
        syonet_user="integration",
        syonet_password="integration",
        syonet_company_id="000001",
    )


@respx.mock
def test_send_success_iso_8859_1():
    route = respx.post("https://mock.syonet.local/api/lead").mock(
        return_value=httpx.Response(
            201,
            content=json.dumps({"leadId": 42, "status": "ok"}, ensure_ascii=False).encode("iso-8859-1"),
            headers={"Content-Type": "application/json; charset=ISO-8859-1"},
        )
    )
    with SyonetConnector(settings=_settings("https://mock.syonet.local")) as c:
        resp = c.send(_sample_lead())

    assert route.called
    request = route.calls.last.request
    assert request.headers["content-type"] == "application/json; charset=ISO-8859-1"
    # garante que o corpo foi codificado em ISO-8859-1 (acento em Paraíso)
    assert "Paraíso".encode("iso-8859-1") in request.content
    assert resp.leadId == 42


@respx.mock
def test_send_412_business_rule():
    respx.post("https://mock.syonet.local/api/lead").mock(
        return_value=httpx.Response(
            412,
            content=json.dumps({"status": "error", "message": "companyId is required"}).encode("iso-8859-1"),
            headers={"Content-Type": "application/json; charset=ISO-8859-1"},
        )
    )
    with SyonetConnector(settings=_settings("https://mock.syonet.local")) as c, pytest.raises(SyonetError) as exc:
        c.send(_sample_lead())
    assert exc.value.status_code == 412


@respx.mock
def test_send_403_unauthorized():
    respx.post("https://mock.syonet.local/api/lead").mock(return_value=httpx.Response(403))
    with SyonetConnector(settings=_settings("https://mock.syonet.local")) as c, pytest.raises(SyonetError) as exc:
        c.send(_sample_lead())
    assert exc.value.status_code == 403


@respx.mock
def test_build_request_includes_gclid_and_additional_fields():
    respx.post("https://mock.syonet.local/api/lead").mock(return_value=httpx.Response(201, content=b"{}"))
    with SyonetConnector(settings=_settings("https://mock.syonet.local")) as c:
        req = c.build_request(_sample_lead())
    assert req.companyId == "000001"
    assert req.event.leadInfo.gclid == "g1"
    assert req.event.leadInfo.fbclid == "f1"
    assert req.additionalFields == {"Brand": "Fiat", "Model": "Toro"}
    assert req.daysToUpdateOpenEvent == 30
