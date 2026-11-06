# ai-service

The AI brain for our Chatwoot install. Chatwoot stays unmodified; this Go
service plugs in through Chatwoot's **Agent Bot** webhook and REST API.

Plan: [DEV-Johnstocker/chatwoot#1](https://github.com/DEV-Johnstocker/chatwoot/issues/1).
This directory implements **phase 2 (MVP: LLM replies + handoff)**.

## How it works

```
Customer ─► Chatwoot ── Agent Bot webhook (HMAC signed) ──► POST /webhooks/chatwoot
                                                              │ verify · filter · dedupe
                                                              ▼ 202 Accepted (fast)
                                                       worker queue (per-conversation order)
                                                              │
              ◄── POST .../messages ◄── LLM (OpenRouter) ◄────┘
              ◄── POST .../toggle_status {status: open}   (handoff)
```

- Answers only **public incoming customer messages** in **`pending`**
  conversations. Ignores private notes, its own replies, activity messages and
  conversations a human has taken (`open`), which prevents reply loops.
- **Handoff** when the customer asks for a human (Thai/Lao/English keywords) or
  when the LLM call fails: sends a short message, adds a private note with the
  reason (`ai-handoff:customer-request` / `ai-handoff:llm-error`) and moves the
  conversation to `open`. An agent can hand it back by setting it to `pending`.
- **Idempotent**: duplicate deliveries of the same message id are dropped.
  When the queue is full it returns `429`, which Chatwoot retries.
- **History**: the last `HISTORY_LIMIT` messages per conversation are kept in
  memory from webhook events, because Chatwoot does not let bot tokens list
  messages. History is lost on restart (persistent store comes with RAG).
- **Logs**: JSON (`log/slog`) with delivery, account, inbox, conversation and
  message ids, model, token counts and latency. Message content is not logged.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| POST | `/webhooks/chatwoot` | Agent Bot webhook (requires valid `X-Chatwoot-Signature`) |
| GET | `/healthz` | Liveness |

## Configuration

All settings are environment variables; see [`.env.example`](.env.example).
Required: `CHATWOOT_BASE_URL`, `CHATWOOT_BOT_TOKEN`, `CHATWOOT_WEBHOOK_SECRET`,
`LLM_API_KEY`, `LLM_MODEL`. The service refuses to start if any is missing.

## Run locally (with `../local` from `init.sh`)

1. Create the admin account at http://localhost:3000 and a website inbox.
2. Create the Agent Bot (Settings → Bots → Add bot) with webhook URL
   `http://ai-service:8080/webhooks/chatwoot`, then connect it to the inbox
   (Inbox settings → Bot configuration).
3. Put the bot's access token and webhook secret, plus your OpenRouter key and
   model, in `local/ai-service.env`.
4. Start it:

   ```bash
   cd local && docker compose --profile ai up -d --build ai-service
   docker compose logs -f ai-service
   ```

`local/.env` sets `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true` so Chatwoot may call
a webhook on the private Docker network. **Local only**; on a server, expose
ai-service over HTTPS and leave that flag off.

## Develop

```bash
go test -race ./...
go vet ./...
gofmt -l .
docker build -t chatwoot-ai-service:dev .
```

Standard library only; no third-party Go modules.
