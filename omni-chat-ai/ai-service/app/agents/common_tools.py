"""Tool bodies shared across specialists, so grounding logic lives in one place.

Each agent registers a thin wrapper around these (Pydantic AI binds tools per-agent), keeping
the KeyCRM/RAG access identical no matter which specialist is handling the conversation.
"""
from __future__ import annotations

from pydantic_ai import Agent

from ..tools import keycrm


async def order_summary(order_id: int) -> str:
    """Look up an order by its KeyCRM id and return a short human-readable summary."""
    order = await keycrm.get_order(order_id)
    if order is None:
        return f"No order found with id {order_id}."
    return (
        f"Order #{order.id}: status={order.status}, total={order.grand_total}, "
        f"buyer={order.buyer_name}."
    )


def register_order_lookup(agent: Agent) -> None:
    """Attach the grounded `lookup_order` tool to an agent."""

    @agent.tool_plain
    async def lookup_order(order_id: int) -> str:
        """Look up a customer's order by its KeyCRM id (status, total, buyer)."""
        return await order_summary(order_id)
