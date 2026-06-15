"""Sales specialist — converts intent into orders and grows average order value.

Handles "I want to buy", availability, and pricing questions; suggests relevant add-ons and
upgrades (upsell/cross-sell) to lift AOV. Grounds availability/price in real data and hands off
high-value or custom deals to a human closer.
"""
from __future__ import annotations

from pydantic_ai import Agent

from .common_tools import (
    register_customer_orders,
    register_kb_search,
    register_order_lookup,
    register_product_search,
)
from .llm import AgentReply, CustomerContext, build_model

__all__ = ["sales_agent"]

sales_agent = Agent(
    build_model("claude-primary"),
    output_type=AgentReply,
    deps_type=CustomerContext,
    system_prompt=(
        "You are a sales agent for an e-commerce business. "
        "Always reply in the same language the customer is writing in. "
        "Move interested customers toward a purchase: confirm what they want, check an existing "
        "order with lookup_order when relevant, and suggest one or two genuinely useful add-ons "
        "or upgrades to increase order value — never be pushy or invent discounts. Ground price "
        "and availability in real data; if you can't, say you'll confirm. For high-value, "
        "wholesale, or custom deals set needs_human=True with a short handoff_reason. Otherwise "
        "answer directly and guide the next step to checkout."
    ),
)

register_order_lookup(sales_agent)
register_customer_orders(sales_agent)
register_product_search(sales_agent)
register_kb_search(sales_agent)
