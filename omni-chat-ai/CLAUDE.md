# Omni-Chat-AI — Claude Code project memory

> Open the `omni-chat-ai/` folder as the working directory so this file, `.claude/agents/`,
> and `.claude/commands/` are picked up. This is the AI/agent subproject; the surrounding repo
> is Chatwoot (its own root `CLAUDE.md` governs Chatwoot core changes).

## What this project is
A Unified Chat Panel (Chatwoot core) + multi-agent AI layer that handles customers across all
channels, hands off to human managers, integrates KeyCRM, and self-evaluates/self-learns.
Read `docs/architecture.md` and `docs/prd/PRD.md` first. Decisions live in `docs/adr/`.

## Non-negotiable rules
1. **No OpenAI lock-in.** Every LLM call goes through LiteLLM (alias `claude-primary`). Never
   import a provider SDK directly in agent code.
2. **Chatwoot owns conversation state & handoff.** Keep the AI service event-driven/stateless;
   don't rebuild conversation storage. Handoff = `pending → open` via Chatwoot REST.
3. **LangGraph MIT library only.** Never add `langgraph-api`/Platform (Elastic License).
4. **Ground all facts via tools.** Agents must use KeyCRM/KB tools for order/customer facts;
   never fabricate. KB gap → escalate.
5. **Typed everything.** Pydantic AI agents return typed outputs; KeyCRM tools use typed models.
6. **OSS-first, minimal custom code.** Prefer the chosen components over new abstractions.
7. **Respect KeyCRM 60 rpm/IP.** Cache and batch.
8. **One inbox = Chatwoot.** Don't double-route messages through KeyCRM chat.

## Architecture (one line)
Channels → Chatwoot (inbox/handoff) → AI service [LangGraph supervisor + Pydantic AI agents] →
tools (KeyCRM, RAG) via LiteLLM→Claude; traced/evaluated in Langfuse.

## Code layout
- `ai-service/app/main.py` — FastAPI webhook entrypoint
- `ai-service/app/graph.py` — LangGraph supervisor (add specialist nodes here)
- `ai-service/app/agents/` — Pydantic AI specialists (support, then consultation/warranty/sales)
- `ai-service/app/tools/` — typed tools (KeyCRM; add RAG `kb.search`, `recommend_upsell`)
- `ai-service/app/chatwoot.py` — REST client + handoff
- `ai-service/app/observability.py` — Langfuse tracing
- `litellm/config.yaml` — model routing/fallbacks
- `docker-compose.yml` — full local stack

## Build / test
- `cp .env.example .env` then fill keys.
- `docker compose up -d` — full stack (Chatwoot :3000, AI :8080, Langfuse :3001, LiteLLM :4000).
- `cd ai-service && uv pip install -e ".[dev]" && pytest` — service tests.
- `ruff check ai-service` — lint.

## Conventions
- Commits: Conventional Commits (`feat(agent): ...`, `docs(adr): ...`). Don't reference Claude.
- New decision? Add an ADR in `docs/adr/` (copy `0000-template.md`).
- New specialist agent → `app/agents/<name>.py` + a node in `graph.py` + a row in the router.
- New channel → see `docs/knowledge/channels.md` (connector pattern).

## Subagents & workflows
- `.claude/agents/` — specialized subagents (integration, agent-dev, eval, channel, docs).
- `.claude/commands/` — slash-command workflows (`/new-agent`, `/add-channel`, `/eval-run`, `/new-adr`).

## context-mode — context window protection (MANDATORY routing)

context-mode MCP is active. Follow these rules to avoid flooding context with raw data.

### Think in Code — MANDATORY
Analyze/count/filter/compare/search/parse data → `ctx_execute(language, code)`, log only the answer.
Do NOT read raw data into context. Pure JavaScript (Node.js built-ins only). One script replaces ten tool calls.

### BLOCKED
- `curl`/`wget` — use `ctx_fetch_and_index(url, source)` or `ctx_execute("javascript", "fetch(...)")`
- Inline HTTP (`fetch(`, `requests.get(`) — route through `ctx_execute`
- Raw `WebFetch` — use `ctx_fetch_and_index(url, source)` then `ctx_search(queries)`

### REDIRECTED
- **Bash >20 lines** — use `ctx_batch_execute(commands, queries)` or `ctx_execute("shell", code)`
- **Read for analysis** — use `ctx_execute_file(path, language, code)`; Read is only for editing

### Tool priority
0. **MEMORY**: `ctx_search(sort: "timeline")` — check prior context on resume before asking user
1. **GATHER**: `ctx_batch_execute(commands, queries)` — one call replaces 30+
2. **SEARCH**: `ctx_search(queries: ["q1", "q2"])` — array of questions, one call
3. **PROCESS**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)`
4. **WEB**: `ctx_fetch_and_index(url, source)` → `ctx_search(queries)`
5. **INDEX**: `ctx_index(content, source)` — store for later retrieval

### On resume
Search BEFORE asking the user what we were doing:
- `ctx_search(queries: ["summary"], source: "compaction", sort: "timeline")`
- `ctx_search(queries: ["decision"], source: "decision")`

### Setup (new developer)
```bash
npm install -g context-mode@latest
context-mode upgrade   # configures Claude Code hooks
context-mode index docs/ --source omni-chat-ai:docs --project .
context-mode doctor    # all checks should pass
```

## Context hygiene — overload & hallucination risk

The model **cannot** self-measure its own token usage; the harness is the source of truth. A
project statusline (`.claude/statusline-context.sh`, wired in `.claude/settings.json`) shows live
`ctx NN%`, and a `PreCompact` hook warns on auto-compaction. Behave accordingly:
- **Green (<70%)** — normal. Still prefer `ctx_*` routing for large outputs.
- **Yellow (70–84%)** — wrap up the current sub-task, avoid pulling large raw data into context,
  lean on `ctx_search`/`ctx_batch_execute`.
- **Red (≥85% or `exceeds_200k`)** — tell the user proactively, recommend `/compact` or a fresh
  session, and on resume `ctx_search` the `compaction` and `decision` sources before continuing.
- Run `/context` anytime for the precise breakdown. After any compaction, re-confirm critical
  facts (order ids, KeyCRM fields, decisions) rather than trusting summarized detail.
