"""End-to-end: webhook → adapter → connector → Syonet mock (in-process)."""

from __future__ import annotations

from fastapi.testclient import TestClient

from dexi_gateway.app import app as gateway_app
from dexi_gateway.mocks.syonet_mock import app as syonet_mock_app


def test_meta_to_syonet_flow_via_direct_connector():
    """Caminho crítico: webhook Meta → adapter → connector → Syonet mock (ASGI in-process)."""
    from dexi_gateway.adapters import meta as meta_adapter
    from dexi_gateway.config import Settings
    from dexi_gateway.syonet_connector import SyonetConnector

    payload = {
        "value": {
            "leadgen_id": "e2e-1",
            "field_data": [
                {"name": "full_name", "values": ["Lorrayne Paraíso"]},
                {"name": "email", "values": ["l@example.com"]},
                {"name": "phone_number", "values": ["+5541999999999"]},
                {"name": "vehicle", "values": ["Toro"]},
            ],
        }
    }
    lead = meta_adapter.normalize(payload, tenant_id="tenant-a")

    settings = Settings(
        syonet_base_url="http://mock",
        syonet_user="integration",
        syonet_password="integration",
        syonet_company_id="000002",
    )

    # TestClient é um httpx.Client síncrono que fala com um app ASGI.
    http = TestClient(syonet_mock_app, base_url="http://mock")
    with SyonetConnector(settings=settings, client=http) as c:
        resp = c.send(lead)

    assert resp.status == "ok"
    assert resp.leadId is not None


def test_gateway_webhook_accepts_and_enqueues(monkeypatch):
    """Verifica que o webhook aceita payload válido e devolve 202.
    Não executa a task Celery — só garante que o contrato HTTP está ok."""
    calls = []
    import dexi_gateway.app as app_module

    monkeypatch.setattr(app_module.process_lead, "delay", lambda payload: calls.append(payload))
    monkeypatch.setattr(app_module, "seen_recently", lambda *_: False)

    client = TestClient(gateway_app)
    resp = client.post(
        "/webhooks/site/tenant-a",
        json={"nome": "Maria", "email": "maria@x.com", "marca": "Jeep", "modelo": "Compass"},
    )
    assert resp.status_code == 202
    assert resp.json()["status"] == "accepted"
    assert len(calls) == 1
    assert calls[0]["tenant_id"] == "tenant-a"


def test_gateway_webhook_dedup(monkeypatch):
    import dexi_gateway.app as app_module

    monkeypatch.setattr(app_module.process_lead, "delay", lambda payload: None)
    monkeypatch.setattr(app_module, "seen_recently", lambda *_: True)

    client = TestClient(gateway_app)
    resp = client.post("/webhooks/site/tenant-a", json={"email": "x@y.com"})
    assert resp.status_code == 202
    assert resp.json()["status"] == "deduplicated"
