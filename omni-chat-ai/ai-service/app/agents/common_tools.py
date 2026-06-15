"""Tool bodies shared across specialists, so grounding logic lives in one place.

Each agent registers a thin wrapper around these (Pydantic AI binds tools per-agent), keeping
the KeyCRM/RAG access identical no matter which specialist is handling the conversation.
"""
from __future__ import annotations

from pydantic_ai import Agent, RunContext

from ..tools import kb, keycrm
from .llm import CustomerContext


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


def register_customer_orders(agent: Agent) -> None:
    """Attach a tool that finds the *current* customer's orders by their Chatwoot phone/email —
    so they never need to quote an order id."""

    @agent.tool
    async def my_orders(ctx: RunContext[CustomerContext]) -> str:
        """Look up the current customer's recent orders using their contact details. Use this
        when the customer asks about their order/delivery without giving an order number."""
        cust = ctx.deps
        buyer = await keycrm.find_buyer(phone=cust.phone, email=cust.email)
        if buyer is None:
            return "No customer record found for this contact in the CRM."
        orders = await keycrm.list_orders_by_buyer(buyer.id)
        if not orders:
            return f"Customer {buyer.full_name or buyer.id} has no orders on record."
        lines = [
            f"Order #{o.id}: status={o.status}, total={o.grand_total}" for o in orders
        ]
        return f"Orders for {buyer.full_name or buyer.id}:\n" + "\n".join(lines)


def register_product_search(agent: Agent) -> None:
    """Attach a catalogue search tool for availability/price grounding."""

    @agent.tool_plain
    async def search_products(query: str) -> str:
        """Search the product catalogue by name; returns price and stock when available."""
        products = await keycrm.search_products(query)
        if not products:
            return f"No products matched '{query}'."
        return "\n".join(
            f"{p.name}: price={p.price}, "
            f"{'in stock' if p.in_stock else 'out of stock' if p.in_stock is False else 'stock unknown'}"
            for p in products
        )


def register_kb_search(agent: Agent) -> None:
    """Attach the knowledge-base search tool so the agent grounds answers in uploaded docs."""

    @agent.tool_plain
    async def knowledge_search(query: str) -> str:
        """Search the product/FAQ/policy knowledge base for passages relevant to the query.

        Returns relevant text, or an empty string if nothing is found — in which case do not
        invent an answer; escalate instead."""
        return await kb.kb_search(query)
