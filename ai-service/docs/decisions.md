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

## Where things are

- Plan, phases and next steps: issue #1 (checklist).
- Working rules for agents: `../AGENTS.md`.
- How the service works and runs locally: `../README.md`; acceptance gates:
  `../ai-service.contract.md`.
- Production setup and deploy procedure: `../deploy/README.md`.
