# Decisions — ai-service

Settled choices for DEV-Johnstocker/chatwoot#1. Don't reopen them without a new
reason; when one changes, edit its row and say why in the PR. Working rules
are in `../AGENTS.md`; the plan and next steps are the checklist on issue #1.

Last reviewed 2026-11-07.

## Product

A multi-channel support chat (LINE OA, Facebook Messenger, Instagram, WhatsApp,
Telegram, website). An AI answers customers from the business's own knowledge
base and hands the chat to a human admin, in the same Chatwoot screen, when it
cannot help. Target market: businesses in Thailand and Laos, LINE and Facebook
first. Owner: John (Johnstocker AI Studio).

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Inbox and channels | Chatwoot, unmodified | Channels, agent mobile app, MIT core, frequent upstream releases |
| Where our code lives | Only `ai-service/` (Go), connected through the Agent Bot webhook and the REST API | Upstream merges stay clean; `enterprise/` is under a separate licence |
| UI inside Chatwoot | Later, through Dashboard Apps (a core feature), not by editing Chatwoot | Same reason |
| Chatwoot Captain AI | Not used | It lives in `enterprise/` and needs a licence |
| agent-desk and sitechat | Ideas only; no code copied so far (see `../NOTICE`) | agent-desk's RAG depends on its GORM models |
| LLM | Any OpenAI-compatible API, with an optional fallback provider; currently OpenAI, OpenRouter supported | Switchable on `/admin` without a restart |
| Claude/Codex subscriptions | Not usable by the service | The service needs API keys |
| Vector store | Postgres with pgvector, not Qdrant | One less service to run |
| Embeddings | OpenAI `text-embedding-3-large` at 1536 dimensions, `RAG_MIN_SCORE=0.3` | Best on the Thai sample eval (18/18 vs 16/18 for `3-small`) |
| Hosting | One VPS (Hostinger, Malaysia, 2 vCPU / 8 GB, shared with other services) running Docker Compose through Dokploy; Traefik serves the public domain | Chatwoot and ai-service are long-running services; Workers or Vercel don't fit |
| Database | Supabase Postgres (Singapore), reached through the session pooler, not the transaction pooler. Chatwoot uses the `chatwoot` database; ai-service uses the project's default `postgres` database | Managed backups and pgvector; Supabase has no Redis |
| Redis | On the VPS, password-protected, append-only file | Supabase has no Redis |
| Public routes | `https://chat.johnstockeraistudio.com` → Chatwoot; `/webhooks/chatwoot` on the same host → ai-service | The Agent Bot webhook goes over public HTTPS, so `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` stays unset |
| `/admin` access | Cloudflare Tunnel `https://ai-admin.johnstockeraistudio.com` behind Cloudflare Access (owner emails), plus ai-service Basic Auth; also an SSH tunnel to VPS loopback | No public port for `/admin` |
| Email | SMTP through Resend on the Chatwoot domain | Required for invites and password resets |
| Deploys | Dokploy deploys branch `develop`; auto-deploy is off. PR → merge → trigger the deploy | Every production change is a reviewed commit; see `../deploy/README.md` |
| Voice, images, stickers | Off by default, switched per business on the Business profile page; transcription `gpt-4o-mini-transcribe` with a vocabulary hint; images to the chat model; sticker check on the small rewrite model; downloads only from the Chatwoot host | Each business decides what reaches the LLM provider; anything unreadable still reaches staff |
| Observability | Langfuse Cloud, Japan region (`jp.cloud.langfuse.com`), over OTLP/HTTP JSON with the standard library; not LangSmith, not self-hosted | Open source (can move to self-hosting later), larger free tier; the VPS can't also run Langfuse's ClickHouse, Redis and object storage |
| Customer data in traces | Redacted in ai-service before export (emails, phones, Thai IDs, card and account numbers, other 9+ digit runs, LINE IDs; Thai and full-width digits too); contact and conversation ids replaced by hashes keyed from the webhook secret, never the Langfuse key; `TRACE_TEXT=off` sends no chat text. Accepted residual risk: names, street addresses and free-form personal details in `redacted` mode reach Langfuse (owner chose redacted over off, 2026-11-07) | Langfuse is a second processor of customer data (PDPA); vendor masking SDKs don't support Go |
| Change history retention | The admin change log (`admin_events`) and the AI-tool log (`kb_audit`) keep old document text so changes can be undone; entries older than 180 days are deleted (`AUDIT_RETENTION_DAYS`). Neither is shown in full in the admin UI, and both are private to the database (RLS on, API roles revoked). | Deleted knowledge must eventually really go away (personal data, old prices), while recent changes stay recoverable. Owner can change the period. |
| Account and inbox names on `/admin` | Taken from signed Agent Bot webhooks (`chatwoot_inboxes`, schema v10), not from the Chatwoot API; every admin sees every known account in the dropdown | The bot token cannot list inboxes, and a staff API token would be one more secret. `/admin` is owner-only today; if per-account admin roles are ever added, the account list must be filtered first |
| AI-app writes to customer-facing text | MCP `update_profile` and `upsert_document` refuse links and domains, @handles, LINE and messenger IDs, and numbers over 6 digits that are not a time, date or price (a price over 6 digits needs a currency); text is NFKD-normalised and invisible characters dropped first; the error does not say which rule matched. Payment words alone (PromptPay, bank, transfer) are allowed: they point nowhere and are common in shop text. Accepted residual risk until owner approval of AI edits exists (#60): wording with no detail ("pay via our Facebook page"), digits written as words, a number split by words or across fields or calls, a number disguised as a list of times, Thai-script domains and "dot com", crypto addresses, and `sync_source` publishing an owner sheet an AI app edited through another connector (owner chose filter now, approval next, 2026-11-09) | A prompt-injected app must not send customers to someone else's account; the owner can make any refused edit on `/admin` |

## Where things are

- Plan, phases and next steps: issue #1 (checklist).
- Working rules for agents: `../AGENTS.md`.
- How the service works and runs locally: `../README.md`; acceptance gates:
  `../ai-service.contract.md`.
- Production setup and deploy procedure: `../deploy/README.md`.
