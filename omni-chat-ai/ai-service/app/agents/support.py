"""Support specialist — a typed Pydantic AI agent.

Runs inside a LangGraph node. Calls the model through LiteLLM (provider-agnostic), so the
same code works with Claude (default), OpenAI, or any provider behind the gateway.
"""
from __future__ import annotations

from pydantic_ai import Agent

from .. import prompts
from ..tools import keycrm
from .common_tools import register_customer_orders, register_kb_search
from .llm import AgentReply, CustomerContext, build_model, to_message_history

__all__ = ["support_agent", "to_message_history"]

DEFAULT_PROMPT = (
    "You are a customer-support agent for an e-commerce business. "
    "Always reply in the same language the customer is writing in. "
    "Be concise, accurate, and friendly. Use tools to look up real order data — "
    "never invent order facts. Prefer the my_orders tool to find the customer's orders by "
    "their contact details; use lookup_order only when they give an order number. If the "
    "customer is angry, asks for a human, requests a refund, or the issue is outside support "
    "(legal/complaints/high-value sales), set needs_human=True with a short handoff_reason. "
    "Otherwise answer directly."
)

support_agent = Agent(
    build_model("claude-primary"),
    output_type=AgentReply,
    deps_type=CustomerContext,
)

prompts.register(support_agent, "support", DEFAULT_PROMPT)
register_customer_orders(support_agent)


@support_agent.tool_plain
async def lookup_order(order_id: int) -> str:
    """Look up an order by its KeyCRM id and return a short human-readable summary."""
    order = await keycrm.get_order(order_id)
    if order is None:
        return f"No order found with id {order_id}."
    return (
        f"Order #{order.id}: status={order.status}, total={order.grand_total}, "
        f"buyer={order.buyer_name}."
    )


register_kb_search(support_agent)
