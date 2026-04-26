from __future__ import annotations

from dexi_gateway.adapters import chatwoot as cw_adapter
from dexi_gateway.adapters.chatwoot import StatusEvent


def test_status_changed_to_open_maps_to_atendimento():
    payload = {
        "event": "conversation_status_changed",
        "conversation": {"id": 42, "status": "open"},
    }
    update = cw_adapter.normalize(payload, tenant_id="t1")
    assert update is not None
    assert update.event == StatusEvent.ATENDIMENTO
    assert update.conversation_id == 42
    assert update.tenant_id == "t1"


def test_status_changed_to_resolved_maps_to_finalizado():
    payload = {
        "event": "conversation_status_changed",
        "conversation": {"id": 17, "status": "resolved"},
    }
    update = cw_adapter.normalize(payload, tenant_id="acme")
    assert update is not None
    assert update.event == StatusEvent.FINALIZADO


def test_status_changed_to_pending_is_ignored():
    # `pending` é o estado inicial — já foi registrado quando o lead chegou pelo portal.
    payload = {
        "event": "conversation_status_changed",
        "conversation": {"id": 1, "status": "pending"},
    }
    assert cw_adapter.normalize(payload, tenant_id="t") is None


def test_assignee_changed_with_assignee_maps_to_atendimento():
    payload = {
        "event": "assignee_changed",
        "conversation": {"id": 99, "status": "pending", "assignee_id": 5},
    }
    update = cw_adapter.normalize(payload, tenant_id="t1")
    assert update is not None
    assert update.event == StatusEvent.ATENDIMENTO


def test_assignee_changed_to_null_is_ignored():
    payload = {
        "event": "assignee_changed",
        "conversation": {"id": 99, "status": "open", "assignee_id": None},
    }
    assert cw_adapter.normalize(payload, tenant_id="t1") is None


def test_conversation_created_is_ignored():
    # Lead já registrado no Syonet via portal — webhook só dispara o N8N AgentBot.
    payload = {"event": "conversation_created", "conversation": {"id": 1}}
    assert cw_adapter.normalize(payload, tenant_id="t1") is None


def test_message_created_is_ignored():
    payload = {"event": "message_created", "id": 999}
    assert cw_adapter.normalize(payload, tenant_id="t1") is None


def test_normalize_handles_flat_payload_shape():
    # Alguns eventos do Chatwoot vêm com a conversa achatada na raiz.
    payload = {
        "event": "conversation_status_changed",
        "id": 8,
        "status": "resolved",
    }
    update = cw_adapter.normalize(payload, tenant_id="t1")
    assert update is not None
    assert update.conversation_id == 8
    assert update.event == StatusEvent.FINALIZADO


def test_payload_without_conversation_id_returns_none():
    payload = {"event": "conversation_status_changed", "status": "open"}
    assert cw_adapter.normalize(payload, tenant_id="t1") is None
