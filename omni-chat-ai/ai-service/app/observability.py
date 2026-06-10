"""Langfuse tracing wrapper.

Self-learning/self-evaluation hub: every conversation turn is traced; online LLM-as-judge and
code evaluators run in Langfuse against these traces. Degrades to a no-op if not configured.
"""
from __future__ import annotations

from contextlib import contextmanager

from .config import settings

try:  # optional dependency at runtime
    from langfuse import Langfuse

    _client = (
        Langfuse(
            host=settings.langfuse_host,
            public_key=settings.langfuse_public_key,
            secret_key=settings.langfuse_secret_key,
        )
        if settings.langfuse_public_key
        else None
    )
except Exception:  # pragma: no cover
    _client = None


@contextmanager
def observe(conversation_id: int, user_message: str):
    if _client is None:
        yield None
        return
    trace = _client.trace(
        name="conversation-turn",
        session_id=str(conversation_id),
        input={"message": user_message},
    )
    try:
        yield trace
    finally:
        _client.flush()
