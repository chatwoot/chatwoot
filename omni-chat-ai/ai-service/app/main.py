"""FastAPI entrypoint — receives Chatwoot agent-bot webhooks and runs the agent graph.

Chatwoot posts events (message_created, conversation_opened, ...) to this URL. We verify the
HMAC signature, ignore the bot's own/outgoing messages, run the LangGraph graph, and let the
graph deliver the reply or hand off. Every run is traced to Langfuse.
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import BackgroundTasks, FastAPI, Header, Request, Response

from . import chatwoot, prompts, settings_service
from .admin import router as admin_router
from .graph import ConvState, graph
from .observability import observe

logger = logging.getLogger("omni-chat-ai")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create the settings store and load saved config into the cache. The service still boots
    # if the DB is unreachable (e.g. unit tests) — env/defaults act as the fallback layer.
    try:
        from .db import init_models

        await init_models()
        await settings_service.refresh()
        await prompts.refresh()
    except Exception as exc:  # pragma: no cover
        logger.warning("settings store unavailable, using env/defaults: %s", exc)
    yield


app = FastAPI(title="Omni-Chat-AI service", lifespan=lifespan)
app.include_router(admin_router)

# Webhooks can be redelivered; remember handled message ids so a retry never double-replies.
# Bounded to avoid unbounded growth (a stateless service, so exact LRU isn't worth it).
_seen_message_ids: set[int] = set()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


# ---------------------------------------------------------------- channel connectors (E-Chat)
@app.post("/connectors/echat/inbound")
async def echat_inbound(
    request: Request,
    background_tasks: BackgroundTasks,
    x_connector_secret: str | None = Header(default=None),
) -> Response:
    """Receive an E-Chat platform event and relay it into the Chatwoot API-channel inbox.

    The endpoint is public, so a shared secret (header or ?token=) is required when configured.
    """
    secret = settings_service.get("echat.webhook_secret")
    if secret:
        provided = x_connector_secret or request.query_params.get("token")
        if provided != secret:
            return Response(status_code=401)
    payload = await request.json()
    from .connectors import echat

    background_tasks.add_task(echat.handle_inbound, payload)
    return Response(status_code=200)


@app.post("/connectors/echat/outbound")
async def echat_outbound(request: Request, background_tasks: BackgroundTasks) -> Response:
    """Receive Chatwoot's API-channel webhook (agent reply) and send it back out via E-Chat."""
    from .connectors import echat

    event = await request.json()
    if event.get("message_type") == "outgoing" and not event.get("private"):
        source_id = ((event.get("conversation") or {}).get("contact_inbox") or {}).get("source_id")
        content = event.get("content")
        if source_id and content:
            background_tasks.add_task(echat.send_to_echat, source_id, content)
    return Response(status_code=200)


@app.post("/webhooks/chatwoot")
async def chatwoot_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_chatwoot_signature: str | None = Header(default=None),
) -> Response:
    raw = await request.body()
    if not chatwoot.verify_signature(raw, x_chatwoot_signature):
        return Response(status_code=401)

    event = await request.json()

    # Only react to inbound customer messages on bot-owned (pending) conversations.
    if event.get("event") != "message_created":
        return Response(status_code=204)
    if event.get("message_type") != "incoming":
        return Response(status_code=204)

    # Guarantee: the bot never speaks while a human owns the conversation (status "open").
    conversation = event.get("conversation", {})
    if conversation.get("status") != "pending":
        return Response(status_code=204)

    message_id = event.get("id")
    if message_id in _seen_message_ids:
        return Response(status_code=200)  # duplicate redelivery — already handled

    conversation_id = conversation.get("id")
    user_message = event.get("content") or ""
    if not conversation_id or not user_message:
        return Response(status_code=204)

    if message_id is not None:
        if len(_seen_message_ids) > 5000:
            _seen_message_ids.clear()
        _seen_message_ids.add(message_id)

    # The customer's CRM identity travels in the payload (conversation.meta.sender), so agents
    # can look up their orders without an order number.
    sender = (conversation.get("meta") or {}).get("sender") or {}
    customer = {
        "name": sender.get("name"),
        "phone": sender.get("phone_number"),
        "email": sender.get("email"),
    }

    # Ack immediately; an LLM turn can take many seconds and Chatwoot would otherwise retry.
    background_tasks.add_task(process_turn, conversation_id, user_message, customer)
    return Response(status_code=200)


async def process_turn(conversation_id: int, user_message: str, customer: dict | None = None) -> None:
    """Run the agent graph out-of-band. On any failure, hand off rather than leave silence."""
    customer = customer or {}
    state: ConvState = {
        "conversation_id": conversation_id,
        "user_message": user_message,
        "customer_name": customer.get("name") or "",
        "customer_phone": customer.get("phone") or "",
        "customer_email": customer.get("email") or "",
    }
    try:
        with observe(conversation_id, user_message):
            await graph.ainvoke(state)
    except Exception as exc:  # fail-safe: silence is the worst outcome in support
        await chatwoot.handoff_to_human(conversation_id, f"AI error, needs a human: {exc}")
