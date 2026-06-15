"""Shared model factory for the Pydantic AI agents.

Every agent talks to the LiteLLM gateway via its OpenAI-compatible API, so swapping providers
is a gateway config change (or a panel save), never a code change. Agents reference stable
aliases (``claude-primary`` / ``claude-fast``) that the admin panel registers at runtime.
"""
from __future__ import annotations

from dataclasses import dataclass

from pydantic import BaseModel
from pydantic_ai import (
    ModelMessage,
    ModelRequest,
    ModelResponse,
    TextPart,
    UserPromptPart,
)
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.openai import OpenAIProvider

from ..config import settings


@dataclass
class CustomerContext:
    """Identity of the customer in the current conversation, from Chatwoot's contact record.

    Lets tools look the customer up in KeyCRM without them quoting an order id.
    """

    name: str | None = None
    phone: str | None = None
    email: str | None = None


def build_model(alias: str = "claude-primary") -> OpenAIChatModel:
    """Return a Pydantic AI model bound to a LiteLLM alias."""
    return OpenAIChatModel(
        alias,
        provider=OpenAIProvider(
            base_url=f"{settings.litellm_base_url}/v1",
            api_key=settings.litellm_master_key,
        ),
    )


class AgentReply(BaseModel):
    """Structured output every specialist returns, so the orchestrator acts deterministically."""

    answer: str
    needs_human: bool = False
    handoff_reason: str | None = None


def to_message_history(messages: list[dict]) -> list[ModelMessage]:
    """Convert Chatwoot history (``{"incoming", "content"}``) into Pydantic AI messages."""
    history: list[ModelMessage] = []
    for m in messages:
        if m["incoming"]:
            history.append(ModelRequest([UserPromptPart(content=m["content"])]))
        else:
            history.append(ModelResponse([TextPart(content=m["content"])]))
    return history
