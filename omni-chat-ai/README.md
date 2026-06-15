# Omni-Chat-AI

A production-oriented, OSS-first **Unified Chat Panel with AI agents**: connect every messenger
(web widget, Telegram bot + personal Telegram, personal Viber, WhatsApp, Instagram DM) into one
inbox, let **AI agents** handle customers (support / consultation / warranty / sales), hand off
cleanly to **human managers**, integrate **KeyCRM**, and **self-evaluate & self-learn** — with
**no OpenAI lock-in** (Claude primary behind a model gateway).

## Start here
- **Architecture:** [`docs/architecture.md`](docs/architecture.md)
- **Product spec:** [`docs/prd/PRD.md`](docs/prd/PRD.md)
- **Decisions:** [`docs/adr/`](docs/adr/)
- **Knowledge:** [`docs/knowledge/`](docs/knowledge/) · **Workflows:** [`docs/workflows/`](docs/workflows/)
- **Claude Code setup:** [`CLAUDE.md`](CLAUDE.md), [`.claude/agents/`](.claude/agents), [`.claude/commands/`](.claude/commands)

## Stack (all OSS unless noted)
Chatwoot CE (inbox/handoff) · LiteLLM (model gateway → Claude) · LangGraph + Pydantic AI
(multi-agent) · LlamaIndex + Qdrant (RAG) · KeyCRM (CRM) · Langfuse + Ragas + Promptfoo (eval) ·
E-Chat.tech / Evolution API (personal-account connectors).

## Quick start (turnkey)
```bash
./deploy.sh                   # generates secrets, brings the whole stack up
```
Then open the **admin panel** at `http://localhost:8080/admin`:
1. Create your administrator account (first-run wizard).
2. Under **Settings**, paste your API keys — Anthropic, KeyCRM, Telegram, Langfuse. Each has a
   **Test connection** button, and the dashboard shows live green/red status.

No `.env` editing: every key is entered in the panel and stored **encrypted** in Postgres. The
Anthropic key is registered with LiteLLM at runtime, so it takes effect with no restart.

- Admin panel: `http://localhost:8080/admin` · Chatwoot inbox: `:3000` · Langfuse: `:3001`

### Deploy on a VPS (recommended)
The stack is many **stateful** services (Postgres, Redis, Qdrant, ClickHouse, Chatwoot
web+worker), so a single VPS running Docker Compose is the cleanest, cheapest home for it.
1. Provision a VPS (≈4 GB RAM+), install Docker, clone this repo.
2. Point DNS at the host and edit the included [`Caddyfile`](Caddyfile) with your domains.
3. `./deploy.sh`, then run Caddy for automatic HTTPS.

Prefer a dashboard/PaaS feel? Install **Coolify** on the same VPS and import this
`docker-compose.yml` — you get click-to-deploy UX while keeping single-host economics.

## AI service
```bash
cd ai-service
uv pip install -e ".[dev]"
pytest                         # smoke tests
uvicorn app.main:app --reload --port 8080
```

## Layout
```
omni-chat-ai/
├── deploy.sh               # one-command installer (generates secrets + brings stack up)
├── Caddyfile               # reverse proxy + automatic HTTPS for a VPS deploy
├── docker-compose.yml      # full local stack
├── litellm/config.yaml     # provider-agnostic model routing (Claude primary)
├── ai-service/             # FastAPI + admin panel + LangGraph supervisor + agents + tools
├── docs/architecture.md    # reference architecture
├── docs/prd/PRD.md         # product requirements
├── docs/adr/               # architecture decision records
├── docs/knowledge/         # integration knowledge (Chatwoot, KeyCRM, channels)
├── docs/workflows/         # operational workflows (handoff)
├── CLAUDE.md               # Claude Code project memory / rules
└── .claude/                # subagents + slash-command workflows
```

> Status: turnkey core. Ships a polished **admin panel** (encrypted settings store, first-run
> wizard, live integration status, per-key Test connection), **runtime LLM key registration**
> with LiteLLM (no restarts, no keys in files), a **four-agent supervisor** (router →
> support / consultation / warranty / sales) with grounded KeyCRM tools and clean Chatwoot
> handoff, Langfuse tracing, and a **one-command deploy**. RAG (Qdrant) and Chatwoot channel
> auto-provisioning wire in next. Extend specialists and channels via `.claude/commands/`.
