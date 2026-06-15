"""Intent router — classifies each turn to the right specialist (supervisor pattern).

A small, fast classification call (uses the cheaper ``claude-fast`` alias) returns one of the
specialist names. The orchestrator (graph) then dispatches to that agent. Defaults to support
when intent is unclear, since support can itself escalate or redirect.
"""
from __future__ import annotations

from typing import Literal

from pydantic import BaseModel
from pydantic_ai import Agent

from .llm import build_model

__all__ = ["router_agent", "Specialist", "RouteDecision"]

Specialist = Literal["support", "consultation", "warranty", "sales"]


class RouteDecision(BaseModel):
    specialist: Specialist = "support"


router_agent = Agent(
    build_model("claude-fast"),
    output_type=RouteDecision,
    system_prompt=(
        "You route an incoming customer message to exactly one specialist. Choose:\n"
        "- 'sales': wants to buy, pricing, availability, placing/upgrading an order.\n"
        "- 'consultation': pre-sale advice, comparing products, 'which should I choose'.\n"
        "- 'warranty': returns, defects, repairs, warranty or after-sales claims.\n"
        "- 'support': order status, delivery, account, or anything else / unclear.\n"
        "Pick the single best fit. When in doubt, choose 'support'."
    ),
)
