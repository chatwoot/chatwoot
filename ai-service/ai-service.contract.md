---
workstream: ai-service
issue: DEV-Johnstocker/chatwoot#1
phase: 2 (MVP)
status: in-review
owner: John
---

# ai-service — workstream contract

## Scope (phase 2)

- Go service in `chatwoot/ai-service/`, Dockerfile, `.env.example`, NOTICE, README.
- Agent Bot webhook endpoint with HMAC verification (`X-Chatwoot-Signature`).
- Filter: only public `incoming` customer messages in `pending` conversations.
- Idempotency by message id; async queue; `429` when full (Chatwoot retries).
- LLM replies through OpenRouter (OpenAI-compatible), model from env.
- Conversation context from webhook events (in-memory, last N turns).
- Reply via `POST .../messages`; typing indicator via `toggle_typing_status`.
- Handoff via `toggle_status {status: open}` on customer request or LLM failure,
  with a customer message and a private note giving the reason.
- Structured JSON logs per reply: model, tokens, latency (no message content).
- Local compose service (`--profile ai`) and `init.sh` support.
- LLM fallback: retry once on `LLM_FALLBACK_*` when the primary fails or times out.
- Settings page `/admin` (Basic Auth, CSRF-protected, write-only keys, Test
  connection, live apply, persisted to `SETTINGS_PATH`).

## Exclusions (later phases)

- RAG / knowledge base / Qdrant (phase 3).
- Answerability Gate, keyword-based escalation rules, labels, business hours (phase 4).
- Dashboard App (phase 5). MCP / workflows (phase 6).
- Rate limits, token budgets, prompt-injection filtering, alerting (phase 7).
- Persistent history (in-memory only; lost on restart).
- Real channel tests (LINE/Messenger) — need a public HTTPS server.

## Deviations from issue #1 (with reason)

- "Fetch recent history from the Chatwoot API": not possible with a bot token —
  `BOT_ACCESSIBLE_ENDPOINTS` (chatwoot `app/controllers/concerns/access_token_auth_helper.rb`)
  allows only `messages#create`. History is built from webhook events instead.
- "Log the message on every AI reply": content is not logged (personal data);
  lengths, ids, tokens and latency are.

## Acceptance gates

Run from `chatwoot/ai-service/`:

```bash
test -z "$(gofmt -l .)"
go vet ./...
go test -race -count=1 ./...
docker build -q -t chatwoot-ai-service:dev .
```

Manual (needs admin account, bot and OpenRouter key):

1. Send a message from the website widget in a pending conversation → AI reply appears.
2. Send "ขอคุยกับแอดมิน" → handoff message, private note `ai-handoff:customer-request`, status `open`.
3. Further customer messages in the `open` conversation get no AI reply.
4. Set a wrong primary key and a valid fallback → replies still arrive, log shows `used_fallback: true`.
5. `/admin`: Test connection succeeds for a valid key; Save applies without restart.

## Evidence

See the PR description for the latest recorded output of the gates.
