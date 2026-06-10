"""LangGraph orchestrator (supervisor pattern).

v1 wires a single Support specialist; Consultation / Warranty / Sales nodes plug in the same
way. State is keyed by the Chatwoot conversation id so multi-turn context is durable when a
checkpointer is attached. Escalation flips the Chatwoot conversation pending → open.

Note: this uses the MIT `langgraph` library only — no Elastic-licensed Platform server.
"""
from __future__ import annotations

from typing import TypedDict

from langgraph.graph import END, StateGraph

from . import chatwoot
from .agents.support import support_agent


class ConvState(TypedDict, total=False):
    conversation_id: int
    user_message: str
    reply: str
    needs_human: bool
    handoff_reason: str


async def route(state: ConvState) -> str:
    """Intent routing entrypoint. v1 always routes to support; extend with a classifier."""
    return "support"


async def support_node(state: ConvState) -> ConvState:
    result = await support_agent.run(state["user_message"])
    out = result.output
    return {
        **state,
        "reply": out.answer,
        "needs_human": out.needs_human,
        "handoff_reason": out.handoff_reason or "",
    }


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
    g.add_node("support", support_node)
    g.add_node("deliver", deliver_node)
    g.set_conditional_entry_point(route, {"support": "support"})
    g.add_edge("support", "deliver")
    g.add_edge("deliver", END)
    return g.compile()


graph = build_graph()
