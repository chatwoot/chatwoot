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

## One-click deploy (any cloud)

**Option A — paste at server creation (truly one click).** When creating a server on
DigitalOcean / Hetzner / AWS / Vultr / Linode, paste [`cloud-init.yaml`](cloud-init.yaml) into the
**User data / Cloud-init** box (edit `DOMAIN` + `ACME_EMAIL` first), then click *Create*. The
server installs Docker and the whole stack automatically and gets HTTPS. ~4 GB RAM recommended.

**Option B — one line on any fresh Ubuntu/Debian server:**
```bash
curl -fsSL https://raw.githubusercontent.com/alekseevconsult-coder/chatwoot/claude/omni-chat-ai-stack-7ydEC/omni-chat-ai/install.sh | bash
# public HTTPS deploy (point example.com AND panel.example.com at the server first):
curl -fsSL .../install.sh | DOMAIN=example.com ACME_EMAIL=you@example.com bash
```

**Option C — Coolify:** install Coolify on a VPS and import this `docker-compose.yml` (dashboard UX).

When it finishes, open **`https://panel.<your-domain>/admin`** (or `http://<server-ip>:8080/admin`),
create your admin account, and paste your API keys under Settings. That's it.

## Quick start (local / already have Docker)
```bash
./deploy.sh                   # generates secrets, brings the whole stack up
# or public HTTPS:  DOMAIN=example.com ACME_EMAIL=you@example.com ./deploy.sh
```
Then open the **admin panel** at `http://localhost:8080/admin`:
1. Create your administrator account (first-run wizard).
2. Under **Settings**, paste your API keys — Anthropic, KeyCRM, Telegram, Langfuse. Each has a
   **Test connection** button, and the dashboard shows live green/red status.

No `.env` editing: every key is entered in the panel and stored **encrypted** in Postgres. The
Anthropic key is registered with LiteLLM at runtime, so it takes effect with no restart.

- Admin panel: `http://localhost:8080/admin` · Chatwoot inbox: `:3000` · Langfuse: `:3001`

When `DOMAIN` is set, a **Caddy** service is added automatically and issues/renews Let's Encrypt
certificates — Chatwoot at `https://DOMAIN`, the admin panel at `https://panel.DOMAIN`. No manual
TLS steps.

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
├── install.sh              # one-line remote bootstrap (installs Docker, clones, deploys)
├── cloud-init.yaml         # paste into a provider's user-data for one-click at server creation
├── deploy.sh               # generates secrets, brings the stack up, adds Caddy/HTTPS if DOMAIN set
├── docker-compose.yml      # full stack (Caddy reverse proxy under the `tls` profile)
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
