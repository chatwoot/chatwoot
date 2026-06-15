# ADR-0006: Admin panel + runtime secrets (keys entered in the UI, not .env)

- **Status:** Accepted
- **Date:** 2026-06-15
- **Deciders:** Omni-Chat-AI core

## Context
The product must be turnkey for a non-DevOps operator: deploy once, then configure everything
from a browser. The original scaffold loaded every key from `.env`, which forces file editing,
container restarts, and risks secrets in plaintext on disk. The Anthropic key is consumed by
LiteLLM (not our service), so "paste a key and it works" needs runtime propagation.

## Decision
Add a Postgres-backed settings store and a server-rendered admin panel (FastAPI + Jinja +
Tailwind/Alpine) in the AI service:
- All user-facing API keys are entered in the panel and stored **Fernet-encrypted** (key
  derived from a single bootstrap `APP_SECRET_KEY`). A synchronous, cache-backed
  `settings_service.get()` overlays saved values over `.env`/defaults, so existing call sites
  stay simple and the service still boots with no DB.
- Single admin account (bcrypt) + signed-cookie sessions; first-run setup wizard.
- LiteLLM runs in **DB mode**; saving the provider key registers the `claude-primary` /
  `claude-fast` aliases via LiteLLM's admin API at runtime — no restart, no key in any file.
- Chatwoot resources (agent bot, web-widget + Telegram inboxes) are auto-provisioned from the
  panel via Chatwoot's REST API.

## Consequences
- **Positive:** zero-file-editing onboarding; secrets encrypted at rest; provider/key changes
  take effect live; one bootstrap secret to protect.
- **Negative:** adds a DB dependency (own `omni_ai` database) and an auth surface to the AI
  service. Rotating `APP_SECRET_KEY` invalidates stored secrets by design (re-enter in panel).
- **Follow-ups:** panel-editable agent prompts; audit log of settings changes.

## Alternatives considered
- Keep `.env`-only → rejected: not turnkey, restarts, plaintext on disk.
- Inject the provider key per-request through LiteLLM → rejected: leaks provider coupling and
  breaks the "all calls via the gateway alias" rule (ADR-0002).
- Separate SPA (React) admin → rejected: heavier build/deploy for no UX gain at this scale.
