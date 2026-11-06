---
workstream: ai-service
issue: DEV-Johnstocker/chatwoot#1
phase: 2 (MVP) + 3 slice 1 (knowledge base)
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

## Scope (phase 3, slice 1)

- Knowledge store in Postgres + pgvector (own database `ai_service`, schema
  migrated on start, HNSW cosine index, iterative scans for filtered search).
- OpenAI-compatible embeddings client (1536 dimensions), configurable on
  `/admin` as a third provider; live switch without restart.
- Thai-safe chunker (paragraph → line → sentence space → length) and Markdown
  section splitting; title + heading prefix on every chunk.
- `/admin/knowledge`: add FAQ, add text/Markdown (paste or upload), delete,
  list with chunk counts, stale-model warning and re-index.
- Scoped retrieval per account and inbox; current-message + context queries
  merged; excerpts given to the model as the only source of business facts.
- Source logging per reply (`kb_document_ids`, `kb_chunk_ids`, `kb_scores`).
- `rag-eval` CLI + sample knowledge base and cases in `testdata/`.

## Scope (phase 3, slice 2)

- Business profile per Chatwoot account (`/admin/business`, schema v2).
- Query rewrite (Thai + English stand-alone query) before knowledge search;
  round-robin merge of multi-query results.
- Handoff keywords are request phrases, not bare words for staff.
- `answer-eval` CLI: multi-turn cases, hard rules + LLM judge.

## Scope (phase 3, slice 3)

- Langfuse tracing over OTLP/HTTP JSON (stdlib): one trace per customer
  message, personal data redacted, ids pseudonymised, `TRACE_TEXT=off` option.

## Exclusions (later phases)

- Phase 3 next slices: PDF/DOCX upload; website crawl with scheduled re-crawl;
  the 50 real customer questions (needs the owner's real content).
- Qdrant: replaced by pgvector (one fewer service; Postgres already runs pgvector).
- agent-desk RAG code: not copied (it depends on agent-desk's GORM models);
  written fresh, so nothing new in NOTICE.
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

- Knowledge content was not taken from Chatwoot's Help Center: bot tokens
  cannot read portal articles. Content is managed on `/admin/knowledge`.

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
6. `/admin` embeddings provider: Test connection reports a 1536-dimension vector.
7. `/admin/knowledge`: add the `testdata/sample-kb` items; each shows its chunk count.
8. `rag-eval` on `testdata/eval-sample.json`: answerable found ≥ 90% with the chosen model.
9. Widget: "ลาเต้เย็นราคาเท่าไหร่" → price from the menu; "ร้านมีสาขาที่ญี่ปุ่นไหม" → "don't know" + offer staff.
10. Change the embeddings model → stale warning → Re-index now → warning gone.

Integration (needs a scratch Postgres with pgvector):

```bash
TEST_DATABASE_URL=postgres://...@localhost:5432/ai_service_test go test -count=1 ./internal/knowledge
```

## Evidence

Phase 3 slice 3, 2026-11-07: unit tests for redaction (11 personal-data shapes
masked, prices/dates/shop LINE OA kept), OTLP encoding, batching, non-blocking
drop, `TRACE_TEXT=off`; live export to Langfuse JP returned four nested
observations (agent, chain, retriever, generation with model and usage) with
the phone number shown as `[PHONE]` and pseudonymous session and user ids.

Phase 3 slice 2, 2026-11-07, production knowledge base (account 1, AutoCut;
buying and refund facts are mock data), `answer-eval` on 22 conversations,
chat model gpt-6-luna judging itself:

- Production code before this slice: 16/22.
- This slice: 22/22 (an earlier run 21/22; the judge wanted more detail in one
  reply). English cases 4/4 pass; before, the English price and Windows
  questions got "I don't know".
- `rag-eval` on 42 retrieval cases: answerable 37/37, MRR 0.939.

See the PR descriptions for the latest recorded output of the gates.

Phase 3 slice 1, 2026-11-06, local Docker (pgvector 0.8.7, PostgreSQL 16):

- Unit + race tests pass; Postgres integration tests pass (2/2).
- `rag-eval` on the 22 sample cases, `RAG_MIN_SCORE=0.3`:
  - `text-embedding-3-small`: answerable 16/18 (89%), MRR 0.889; unanswerable 3/4 empty.
  - `text-embedding-3-large`: answerable 18/18 (100%), MRR 1.000; unanswerable 2/4 empty
    (the two weak matches did not contain an answer; the model said it did not know).
- Live widget conversation: latte price, oat-milk follow-up, PromptPay, Japan
  branch ("don't know"), spilled-latte refund all answered correctly.
