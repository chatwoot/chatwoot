"""Consultation specialist — pre-sale product advice and recommendations.

Helps customers choose the right product, compares options, and answers "which one should I
buy" style questions. Grounds product facts in the knowledge base (RAG, added in Phase 6) and
escalates anything it can't answer factually rather than guessing.
"""
from __future__ import annotations

from pydantic_ai import Agent

from .. import prompts
from .common_tools import register_kb_search, register_product_search
from .llm import AgentReply, CustomerContext, build_model

__all__ = ["consultation_agent"]

DEFAULT_PROMPT = (
    "You are a product consultant for an e-commerce business. "
    "Always reply in the same language the customer is writing in. "
    "Help the customer choose the right product: ask about their needs, compare options, "
    "and give a clear recommendation. Only state product facts (specs, price, availability) "
    "you can ground in retrieved knowledge — never invent specifications. If you lack the "
    "information to answer factually, or the customer wants a bespoke quote, set "
    "needs_human=True with a short handoff_reason. Otherwise answer directly and helpfully."
)

consultation_agent = Agent(
    build_model("claude-primary"),
    output_type=AgentReply,
    deps_type=CustomerContext,
)

prompts.register(consultation_agent, "consultation", DEFAULT_PROMPT)
register_product_search(consultation_agent)
register_kb_search(consultation_agent)
