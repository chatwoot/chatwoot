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
| GET/POST | `/admin` | LLM provider settings page (only when `ADMIN_PASSWORD` is set) |

## Configuration

All settings are environment variables; see [`.env.example`](.env.example).
Required: `CHATWOOT_BASE_URL`, `CHATWOOT_BOT_TOKEN`, `CHATWOOT_WEBHOOK_SECRET`.
The service refuses to start if any is missing.

### LLM provider

The LLM client speaks the OpenAI Chat Completions format, so any compatible
provider works. You switch providers with three variables:

| Provider | `LLM_BASE_URL` | `LLM_API_KEY` | `LLM_MODEL` example |
|---|---|---|---|
| OpenRouter (default) | `https://openrouter.ai/api/v1` | OpenRouter key | a slug from openrouter.ai/models |
| OpenAI | `https://api.openai.com/v1` | OpenAI key | a model id from platform.openai.com/docs/models |

Restart ai-service after changing env values (or use the settings page, which
applies changes live).

**Fallback:** set `LLM_FALLBACK_BASE_URL`, `LLM_FALLBACK_API_KEY` and
`LLM_FALLBACK_MODEL` to a second provider. When the primary call fails or times
out, ai-service retries once on the fallback; the reply log shows
`used_fallback: true`. If both fail, the chat is handed to a human.

LLM settings are not required at startup. Without a provider, every chat is
handed to a human until one is configured.

### Settings page (`/admin`)

Set `ADMIN_PASSWORD` (12+ characters) to enable `http://localhost:8080/admin`
(user `admin`). There you can set the primary and fallback provider, test each
one with **Test connection**, and save. Saved settings take effect immediately
and are stored in `SETTINGS_PATH` (default `/data/settings.json`, file mode
0600, on the `ai_data` volume). A saved file overrides the `LLM_*` env values.

- API keys are write-only: the page shows only the last 4 characters. A blank
  key field keeps the saved key only while the base URL stays the same; change
  the URL and you must enter the key again, so a saved key never goes to a new host.
- Base URLs with `user:pass@` are rejected; logs record only the host.
- Accepted risk: an admin can point the base URL at any address, including
  private ones, because local models (e.g. Ollama) need that. Only the HTTP
  status and the provider's error message are shown back.
- To remove the fallback, clear its base URL and model and save.
- Protection: HTTP Basic Auth, cross-origin form posts rejected, strict CSP,
  `no-store`. Outside localhost, serve it only over HTTPS.
- To show it inside Chatwoot, add it as a Dashboard App (phase 5).

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
