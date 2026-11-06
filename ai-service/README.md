# ai-service

The AI brain for our Chatwoot install. Chatwoot stays unmodified; this Go
service plugs in through Chatwoot's **Agent Bot** webhook and REST API.

Plan: [DEV-Johnstocker/chatwoot#1](https://github.com/DEV-Johnstocker/chatwoot/issues/1).
This directory implements **phase 2 (MVP: LLM replies + handoff)** and
**phase 3, slice 1 (knowledge base: FAQ + text/Markdown documents)**.

## How it works

```
Customer ─► Chatwoot ── Agent Bot webhook (HMAC signed) ──► POST /webhooks/chatwoot
                                                              │ verify · filter · dedupe
                                                              ▼ 202 Accepted (fast)
                                                       worker queue (per-conversation order)
                                                              │
                                                 knowledge base search (pgvector)
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
- **Knowledge base (RAG)**: for each reply the bot searches the account's
  knowledge (this inbox's documents plus account-wide ones) with the current
  message alone and together with the previous one, merges the best matches
  and gives the top `RAG_TOP_K` above `RAG_MIN_SCORE` to the model as the only
  source for business facts. With no match the model is told to say it does
  not know and offer a staff member. The reply log lists `kb_document_ids`,
  `kb_chunk_ids` and `kb_scores` (no content).
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
| GET/POST | `/admin` | AI provider settings page (only when `ADMIN_PASSWORD` is set) |
| GET/POST | `/admin/knowledge` | Knowledge base page (also needs `DATABASE_URL`) |

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

- API keys are write-only: a saved key is never written into the page, only
  its last 4 characters. A key you just typed is refilled after **Test
  connection** so a following **Save** stores it. A blank
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

### Knowledge base (`/admin/knowledge`)

Needs `DATABASE_URL` (Postgres with pgvector; locally the `ai_service`
database that `init.sh` creates on the Chatwoot Postgres) and an
**embeddings provider** on `/admin` (recommended: OpenAI
`text-embedding-3-large`; with the same base URL as the primary, leave its key
blank to reuse the primary key). The schema is created on startup.

- Add **FAQs** (question + answer) or **documents** (paste text, or upload
  `.txt`/`.md` up to 2 MB). Markdown is split at its headings, then into
  chunks of about `RAG_CHUNK_RUNES` characters; every chunk carries the
  document title and section heading. Thai text is split at paragraphs, lines
  and sentence spaces, never mid-word unless a run has no spaces at all.
- Knowledge is per Chatwoot **account**; an optional **inbox ID** limits a
  document to one channel (blank = all inboxes).
- Vectors are tied to the embeddings model. After changing the model the page
  shows how many chunks are stale and offers **Re-index now**.
- PDF/DOCX and website crawling are the next slices (see the contract).

### Measuring retrieval (`rag-eval`)

`rag-eval` runs a JSON list of test questions through the same search the bot
uses and reports how many found the expected document (hit rate, MRR) and how
many questions without an answer correctly found nothing:

```bash
docker compose cp my-eval.json ai-service:/data/eval.json
docker compose exec ai-service /rag-eval -cases /data/eval.json            # current settings
docker compose exec ai-service /rag-eval -cases /data/eval.json -min-score 0.35
```

Each case: `{"question": "...", "account_id": 1, "inbox_id": 0, "expect": "part of the expected title"}`;
`"expect": ""` means the bot should find nothing and hand off. A sample shop
knowledge base and 22 cases are in [`testdata/`](testdata/). On that sample
(Thai + English), `text-embedding-3-small` found 16/18, `text-embedding-3-large`
18/18 at `RAG_MIN_SCORE=0.3`.

### Measuring answers (`answer-eval`)

`answer-eval` grades the bot's real replies to multi-turn test conversations.
It uses the same business profile, knowledge search, query rewrite and chat
model as ai-service, and sends nothing to Chatwoot. Each case is checked by
hard rules first (handoff, required and forbidden text), then by an LLM judge
that fails wrong answers and invented business facts:

```bash
docker compose cp answers.json ai-service:/data/answers.json
docker compose exec ai-service /answer-eval -cases /data/answers.json -v           # every reply
docker compose exec ai-service /answer-eval -cases /data/answers.json -no-rewrite  # compare without the rewrite
```

Each case: `{"name", "account_id", "turns": ["...", "..."], "expect": "answer|unknown|handoff",
"must_include": ["3,900|3900"], "must_not_include": [], "note": "what a correct reply says"}`.
Only the reply to the last turn is graded. A case costs about two model calls
per turn plus one judge call; `-judge-model` grades with a different model.

### Tracing (Langfuse)

With `LANGFUSE_BASE_URL`, `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY` set,
each customer message becomes one Langfuse trace: a `chat-turn` span with
`query-rewrite`, `knowledge-search` (retrieved titles and scores) and `answer`
(model, tokens, latency) children, and the outcome (`replied` or
`handoff:<reason>`). It is sent over OTLP/HTTP JSON in the background; a full
buffer drops turns instead of delaying replies.

Before anything leaves the server, emails, phone numbers, Thai national IDs,
card and bank account numbers and labelled LINE IDs are masked, and contact
and conversation ids become keyed hashes (`langfuse.user.id`,
`langfuse.session.id`) with a key derived from the Chatwoot webhook secret,
which Langfuse never sees. Redaction is best effort: names and street
addresses are not detected. `TRACE_TEXT=off` sends no chat text at all.
`TRACE_ENVIRONMENT` (default `production`) tags the traces. To send one sample
trace from your machine: `LANGFUSE_LIVE=1 go test -run Live ./internal/trace`.

### Query rewrite

Before searching, the bot asks the chat model to rewrite the customer's last
message, with the conversation for context, as one stand-alone query in Thai
and one in English. Both are searched alongside the customer's own words, so
an English question finds a Thai knowledge base and "how much is it?" finds
its topic. Results are merged round-robin, so each query keeps its best hit.
If the rewrite fails, the bot searches with the customer's words only.

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
# Postgres integration tests (scratch database with pgvector; tables are recreated):
TEST_DATABASE_URL=postgres://postgres:PASSWORD@localhost:5432/ai_service_test go test ./internal/knowledge
go vet ./...
gofmt -l .
docker build -t chatwoot-ai-service:dev .
```

Standard library plus one module: `github.com/jackc/pgx/v5` (Postgres driver;
the protocol is not worth hand-rolling). Vectors are sent as pgvector text
literals, so no pgvector client library is needed.
