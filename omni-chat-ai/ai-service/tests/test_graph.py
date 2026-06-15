"""Graph orchestration tests: routing, delivery, and handoff (no live LLM/Chatwoot)."""
from __future__ import annotations

from types import SimpleNamespace

import pytest

from app import chatwoot, graph
from app.agents import router as router_mod
from app.agents.llm import AgentReply
from app.agents.router import RouteDecision


@pytest.fixture
def stub_chatwoot(monkeypatch):
    sent: list[tuple] = []
    handoffs: list[tuple] = []

    async def fake_history(cid, limit=10):
        return []

    async def fake_send(cid, content, private=False):
        sent.append((cid, content, private))

    async def fake_handoff(cid, summary):
        handoffs.append((cid, summary))

    monkeypatch.setattr(chatwoot, "fetch_history", fake_history)
    monkeypatch.setattr(chatwoot, "send_reply", fake_send)
    monkeypatch.setattr(chatwoot, "handoff_to_human", fake_handoff)
    return sent, handoffs


def _stub_agent_run(monkeypatch, agent, reply: AgentReply):
    async def fake_run(*args, **kwargs):
        return SimpleNamespace(output=reply)

    monkeypatch.setattr(agent, "run", fake_run)


async def test_routes_to_sales_and_delivers(monkeypatch, stub_chatwoot):
    sent, handoffs = stub_chatwoot

    async def fake_router(*args, **kwargs):
        return SimpleNamespace(output=RouteDecision(specialist="sales"))

    monkeypatch.setattr(router_mod.router_agent, "run", fake_router)
    _stub_agent_run(monkeypatch, graph.SPECIALISTS["sales"], AgentReply(answer="Here's a deal!"))

    state = await graph.graph.ainvoke({"conversation_id": 7, "user_message": "I want to buy"})

    assert state["specialist"] == "sales"
    assert sent == [(7, "Here's a deal!", False)]
    assert handoffs == []


async def test_escalation_triggers_handoff(monkeypatch, stub_chatwoot):
    sent, handoffs = stub_chatwoot

    async def fake_router(*args, **kwargs):
        return SimpleNamespace(output=RouteDecision(specialist="warranty"))

    monkeypatch.setattr(router_mod.router_agent, "run", fake_router)
    _stub_agent_run(
        monkeypatch,
        graph.SPECIALISTS["warranty"],
        AgentReply(answer="", needs_human=True, handoff_reason="refund on order 42"),
    )

    await graph.graph.ainvoke({"conversation_id": 9, "user_message": "I want a refund"})

    assert handoffs == [(9, "refund on order 42")]


async def test_router_failure_falls_back_to_support(monkeypatch, stub_chatwoot):
    sent, _ = stub_chatwoot

    async def boom(*args, **kwargs):
        raise RuntimeError("router down")

    monkeypatch.setattr(router_mod.router_agent, "run", boom)
    _stub_agent_run(monkeypatch, graph.SPECIALISTS["support"], AgentReply(answer="How can I help?"))

    state = await graph.graph.ainvoke({"conversation_id": 3, "user_message": "hello"})

    assert state["specialist"] == "support"
    assert sent == [(3, "How can I help?", False)]
