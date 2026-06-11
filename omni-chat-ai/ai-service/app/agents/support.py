"""Support specialist — a typed Pydantic AI agent.

Runs inside a LangGraph node. Calls the model through LiteLLM (provider-agnostic), so the
same code works with Claude (default), OpenAI, or any provider behind the gateway.
"""
from __future__ import annotations

from pydantic import BaseModel
from pydantic_ai import (
    Agent,
    ModelMessage,
    ModelRequest,
    ModelResponse,
    TextPart,
    UserPromptPart,
)
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.openai import OpenAIProvider

from ..config import settings
from ..tools import keycrm

# LiteLLM serves an OpenAI-compatible API, so we point Pydantic AI's OpenAIChatModel at the
# gateway base URL. Swapping providers is a config change (litellm/config.yaml), not a code change.
_model = OpenAIChatModel(
    settings.agent_model,
    provider=OpenAIProvider(
        base_url=f"{settings.litellm_base_url}/v1",
        api_key=settings.litellm_master_key,
    ),
)


class SupportReply(BaseModel):
    """Structured output the orchestrator can act on deterministically."""

    answer: str
    needs_human: bool = False
    handoff_reason: str | None = None


support_agent = Agent(
    _model,
    output_type=SupportReply,
    system_prompt=(
        "You are a customer-support agent for an e-commerce business. "
        "Always reply in the same language the customer is writing in. "
        "Be concise, accurate, and friendly. Use tools to look up real order data — "
        "never invent order facts. If the customer is angry, asks for a human, requests a "
        "refund, or the issue is outside support (legal/complaints/high-value sales), set "
        "needs_human=True with a short handoff_reason. Otherwise answer directly."
    ),
)


def to_message_history(messages: list[dict]) -> list[ModelMessage]:
    """Convert Chatwoot history (``{"incoming", "content"}``) into Pydantic AI messages."""
    history: list[ModelMessage] = []
    for m in messages:
        if m["incoming"]:
            history.append(ModelRequest([UserPromptPart(content=m["content"])]))
        else:
            history.append(ModelResponse([TextPart(content=m["content"])]))
    return history


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
