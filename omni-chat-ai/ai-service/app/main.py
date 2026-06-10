"""FastAPI entrypoint — receives Chatwoot agent-bot webhooks and runs the agent graph.

Chatwoot posts events (message_created, conversation_opened, ...) to this URL. We verify the
HMAC signature, ignore the bot's own/outgoing messages, run the LangGraph graph, and let the
graph deliver the reply or hand off. Every run is traced to Langfuse.
"""
from __future__ import annotations

from fastapi import FastAPI, Header, Request, Response

from . import chatwoot
from .graph import ConvState, graph
from .observability import observe

app = FastAPI(title="Omni-Chat-AI service")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/webhooks/chatwoot")
async def chatwoot_webhook(
    request: Request,
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

    conversation = event.get("conversation", {})
    conversation_id = conversation.get("id")
    user_message = event.get("content") or ""
    if not conversation_id or not user_message:
        return Response(status_code=204)

    state: ConvState = {"conversation_id": conversation_id, "user_message": user_message}
    with observe(conversation_id, user_message):
        await graph.ainvoke(state)

    return Response(status_code=200)
