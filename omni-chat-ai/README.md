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

## Run locally
```bash
cp .env.example .env          # fill in keys (Anthropic, Chatwoot bot token, KeyCRM, Langfuse)
docker compose up -d          # Chatwoot :3000 · AI :8080 · Langfuse :3001 · LiteLLM :4000
```
Then in Chatwoot: create an **Agent Bot** (Settings → Integrations → Bots) with outgoing URL
`http://ai-service:8080/webhooks/chatwoot`, copy its token + HMAC secret into `.env`, and attach
the bot to an inbox.

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
├── docker-compose.yml      # full local stack
├── litellm/config.yaml     # provider-agnostic model routing (Claude primary)
├── ai-service/             # FastAPI + LangGraph supervisor + Pydantic AI agents + tools
├── docs/architecture.md    # reference architecture
├── docs/prd/PRD.md         # product requirements
├── docs/adr/               # architecture decision records
├── docs/knowledge/         # integration knowledge (Chatwoot, KeyCRM, channels)
├── docs/workflows/         # operational workflows (handoff)
├── CLAUDE.md               # Claude Code project memory / rules
└── .claude/                # subagents + slash-command workflows
```

> Status: scaffold (P1). The AI service ships a working webhook + one Support agent + KeyCRM
> tool + Chatwoot handoff. Extend specialists and channels via the `.claude/commands/`.
