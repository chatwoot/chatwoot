"""Langfuse tracing wrapper.

Self-learning/self-evaluation hub: every conversation turn is traced; online LLM-as-judge and
code evaluators run in Langfuse against these traces. Degrades to a no-op if not configured.

The client is built lazily from ``settings_service`` so keys entered in the admin panel take
effect without a restart. It is rebuilt if the configured keys change.
"""
from __future__ import annotations

from contextlib import contextmanager

from . import settings_service

try:  # optional dependency at runtime
    from langfuse import Langfuse
except Exception:  # pragma: no cover
    Langfuse = None  # type: ignore[assignment]

_client = None
_client_key: tuple[str, str, str] | None = None


def _get_client():
    """Return a cached Langfuse client, rebuilding it when the configured keys change."""
    global _client, _client_key
    if Langfuse is None:
        return None
    public = settings_service.get("langfuse.public_key")
    secret = settings_service.get("langfuse.secret_key")
    host = settings_service.get("langfuse.host")
    if not public:
        _client, _client_key = None, None
        return None
    key = (public, secret, host)
    if key != _client_key:
        try:
            _client = Langfuse(host=host, public_key=public, secret_key=secret)
            _client_key = key
        except Exception:  # pragma: no cover
            _client, _client_key = None, None
    return _client


@contextmanager
def observe(conversation_id: int, user_message: str):
    client = _get_client()
    if client is None:
        yield None
        return
    trace = client.trace(
        name="conversation-turn",
        session_id=str(conversation_id),
        input={"message": user_message},
    )
    try:
        yield trace
    finally:
        client.flush()
