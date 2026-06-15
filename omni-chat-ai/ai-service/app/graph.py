"""LangGraph orchestrator (supervisor pattern).

A fast router classifies each turn to one of four specialists — support, consultation,
warranty, sales — each a typed Pydantic AI agent. State is keyed by the Chatwoot conversation
id so multi-turn context is durable when a checkpointer is attached. Escalation flips the
Chatwoot conversation pending → open.

Note: this uses the MIT `langgraph` library only — no Elastic-licensed Platform server.
"""
from __future__ import annotations

from typing import TypedDict

from langgraph.graph import END, StateGraph

from . import chatwoot
from .agents.consultation import consultation_agent
from .agents.llm import CustomerContext, to_message_history
from .agents.router import router_agent
from .agents.sales import sales_agent
from .agents.support import support_agent
from .agents.warranty import warranty_agent

# Specialist name → its agent. Adding a specialist is one entry here plus a router category.
SPECIALISTS = {
    "support": support_agent,
    "consultation": consultation_agent,
    "warranty": warranty_agent,
    "sales": sales_agent,
}


class ConvState(TypedDict, total=False):
    conversation_id: int
    user_message: str
    customer_name: str
    customer_phone: str
    customer_email: str
    specialist: str
    reply: str
    needs_human: bool
    handoff_reason: str


async def route(state: ConvState) -> str:
    """Classify the turn to a specialist; fall back to support on any routing failure."""
    try:
        decision = await router_agent.run(state["user_message"])
        specialist = decision.output.specialist
    except Exception:
        specialist = "support"
    return specialist if specialist in SPECIALISTS else "support"


def _make_specialist_node(name: str):
    agent = SPECIALISTS[name]

    async def node(state: ConvState) -> ConvState:
        history = await chatwoot.fetch_history(state["conversation_id"])
        # The current message is already persisted in Chatwoot; drop it from history so the
        # agent doesn't see it twice (once as history, once as the prompt).
        if history and history[-1]["incoming"] and history[-1]["content"] == state["user_message"]:
            history = history[:-1]
        deps = CustomerContext(
            name=state.get("customer_name"),
            phone=state.get("customer_phone"),
            email=state.get("customer_email"),
        )
        result = await agent.run(
            state["user_message"], message_history=to_message_history(history), deps=deps
        )
        out = result.output
        return {
            **state,
            "specialist": name,
            "reply": out.answer,
            "needs_human": out.needs_human,
            "handoff_reason": out.handoff_reason or "",
        }

    return node


async def deliver_node(state: ConvState) -> ConvState:
    """Send the reply, or hand off to a human manager."""
    cid = state["conversation_id"]
    if state.get("needs_human"):
        await chatwoot.handoff_to_human(cid, state.get("handoff_reason") or "Escalation requested")
    else:
        await chatwoot.send_reply(cid, state["reply"])
    return state


def build_graph():
    g = StateGraph(ConvState)
    for name in SPECIALISTS:
        g.add_node(name, _make_specialist_node(name))
        g.add_edge(name, "deliver")
    g.add_node("deliver", deliver_node)
    g.set_conditional_entry_point(route, {name: name for name in SPECIALISTS})
    g.add_edge("deliver", END)
    return g.compile()


graph = build_graph()
