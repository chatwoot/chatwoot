from __future__ import annotations

import httpx
import pytest
import respx

from dexi_gateway.chatwoot_connector import ChatwootConnector, ChatwootError
from dexi_gateway.config import Settings
from dexi_gateway.models.lead import (
    LeadAttribution,
    LeadChannel,
    LeadCustomer,
    LeadIntent,
    LeadPhone,
    NormalizedLead,
)


def _sample_lead() -> NormalizedLead:
    return NormalizedLead(
        lead_id="l-1",
        tenant_id="t1",
        channel=LeadChannel.SITE,
        customer=LeadCustomer(
            external_id="cpf-123",
            first_name="Maria",
            last_name="Silva",
            phones=[LeadPhone(number="+5541988888888")],
            emails=["maria@example.com"],
        ),
        attribution=LeadAttribution(utm_source="google", utm_campaign="black-friday"),
        intent=LeadIntent(brand="Jeep", model="Compass", observations="Quer test drive"),
    )


def _settings(**overrides) -> Settings:
    base = {
        "chatwoot_enabled": True,
        "chatwoot_base_url": "https://chatwoot.test",
        "chatwoot_api_token": "token-abc",
        "chatwoot_account_id": 7,
        "chatwoot_default_inbox_id": 42,
    }
    base.update(overrides)
    return Settings(**base)


def test_push_lead_creates_contact_then_conversation():
    settings = _settings()
    base = "https://chatwoot.test/api/v1/accounts/7"

    with respx.mock(assert_all_called=True) as mock:
        mock.get(f"{base}/contacts/search").respond(200, json={"payload": []})
        mock.post(f"{base}/contacts").respond(
            201, json={"payload": {"contact": {"id": 99, "identifier": "cpf-123"}}}
        )
        mock.post(f"{base}/conversations").respond(
            201, json={"id": 555, "status": "pending"}
        )

        with ChatwootConnector(settings, client=httpx.Client()) as cw:
            ids = cw.push_lead(_sample_lead())

    assert ids == {"contact_id": 99, "conversation_id": 555}


def test_push_lead_reuses_existing_contact():
    settings = _settings()
    base = "https://chatwoot.test/api/v1/accounts/7"

    with respx.mock(assert_all_called=True) as mock:
        mock.get(f"{base}/contacts/search").respond(
            200,
            json={"payload": [{"id": 12, "identifier": "cpf-123"}]},
        )
        mock.post(f"{base}/conversations").respond(201, json={"id": 777})

        with ChatwootConnector(settings, client=httpx.Client()) as cw:
            ids = cw.push_lead(_sample_lead())

    assert ids == {"contact_id": 12, "conversation_id": 777}


def test_push_lead_uses_explicit_inbox_id_over_default():
    settings = _settings(chatwoot_default_inbox_id=999)
    base = "https://chatwoot.test/api/v1/accounts/7"

    with respx.mock() as mock:
        mock.get(f"{base}/contacts/search").respond(200, json={"payload": []})
        mock.post(f"{base}/contacts").respond(201, json={"payload": {"contact": {"id": 1}}})
        route = mock.post(f"{base}/conversations").respond(201, json={"id": 2})

        with ChatwootConnector(settings, client=httpx.Client()) as cw:
            cw.push_lead(_sample_lead(), inbox_id=42)

    import json as _json
    body = _json.loads(route.calls.last.request.read())
    assert body["inbox_id"] == 42


def test_push_lead_raises_when_no_inbox_configured():
    settings = _settings(chatwoot_default_inbox_id=None)
    with respx.mock(), pytest.raises(ValueError, match="inbox_id is required"):
        with ChatwootConnector(settings, client=httpx.Client()) as cw:
            cw.push_lead(_sample_lead())


def test_connector_raises_when_credentials_missing():
    settings = Settings(chatwoot_enabled=True, chatwoot_base_url=None, chatwoot_api_token=None)
    with pytest.raises(ValueError, match="chatwoot_base_url"):
        ChatwootConnector(settings)


def test_create_contact_propagates_http_error():
    settings = _settings()
    base = "https://chatwoot.test/api/v1/accounts/7"

    with respx.mock() as mock:
        mock.get(f"{base}/contacts/search").respond(200, json={"payload": []})
        mock.post(f"{base}/contacts").respond(422, text='{"message":"invalid"}')

        with pytest.raises(ChatwootError) as exc, ChatwootConnector(settings, client=httpx.Client()) as cw:
            cw.push_lead(_sample_lead())

    assert exc.value.status_code == 422
