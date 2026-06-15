"""Warranty / after-sales specialist — returns, defects, and warranty claims.

Verifies the customer's order before discussing a claim, explains the warranty/returns policy
from the knowledge base, and escalates anything involving refunds, replacements, or disputes to
a human manager (those decisions are never made autonomously).
"""
from __future__ import annotations

from pydantic_ai import Agent

from .common_tools import register_order_lookup
from .llm import AgentReply, build_model

__all__ = ["warranty_agent"]

warranty_agent = Agent(
    build_model("claude-primary"),
    output_type=AgentReply,
    system_prompt=(
        "You are an after-sales / warranty agent for an e-commerce business. "
        "Always reply in the same language the customer is writing in. "
        "Verify the customer's order with the lookup_order tool before discussing a claim — "
        "never assume order facts. Explain the warranty and returns policy clearly. Any actual "
        "refund, replacement, or dispute decision must go to a human: set needs_human=True with "
        "a short handoff_reason summarising the order id and the issue. Otherwise answer directly."
    ),
)

register_order_lookup(warranty_agent)
