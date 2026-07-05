# ADR-0004: The agentic-AI usage cap is enforced externally; Chatwoot only displays it

**Status:** Accepted (2026-07-04)
**Relates to:** `CHATWOOT_ENGINE_INTEGRATION.md` §5, `docs/fork/ENTITLEMENTS.md`.

## Context

Plans cap **agentic-AI usage** (automated-workflow / token spend per period). The
question is where that cap is counted and enforced. Every AI action happens in the
external LangGraph orchestrator; Chatwoot never runs the model and has no notion of
"tokens". Duplicating a counter in Chatwoot would be a second source of truth that
is always stale relative to the orchestrator.

This is deliberately different from Chatwoot-owned **capacity** resources
(agents, inboxes, teams, agent_bots, webhooks, labels, …), which Chatwoot both
owns and enforces (`Custom::EntitlementService`, 402/422 denials).

## Decision

**The agentic-AI cap is enforced by the orchestrator (meta-saas); Chatwoot only
displays it.**

- The control plane writes two fields via the Platform API
  (`PATCH /platform/api/v1/accounts/{id}`, full-object jsonb writes):
  - `limits.agentic_ai` — the cap.
  - `custom_attributes.agentic_ai_usage` — current usage.
- `agentic_ai` is a schema-valid limit key but has **no** `EntitlementService`
  counter/guard (`custom/app/models/custom/account/plan_usage_and_limits.rb`:
  `EXTERNAL_LIMIT_KEYS`).
- `GET /enterprise/api/v1/accounts/{id}/limits` returns
  `agentic_ai: { allowed, consumed }` **only when the cap is set**.
- The dashboard shows an admin warning banner when `consumed >= allowed`
  (`app/javascript/dashboard/fork/AgenticAiLimitBanner.vue`). Display-only: there
  is no Chatwoot create-path, no 402, and no server-side block for `agentic_ai`.

## Consequences

- **If the orchestrator does not enforce the cap, nothing does.** Stopping AI
  replies over the cap is mandatory orchestrator logic
  (`CHATWOOT_ENGINE_INTEGRATION.md` §7.9-B).
- Usage writes **replace** the `limits` / `custom_attributes` jsonb (they do not
  merge), so the control plane must hold the authoritative full objects and
  prefer batched/periodic usage updates over a PATCH per AI action.
- The banner is eventually-consistent: it refreshes on the tenant's next limits
  fetch, not in real time.
- This split keeps Chatwoot authoritative for what it owns (conversation state,
  capacity resources) and the platform authoritative for what it owns (AI usage,
  billing) — consistent with ADR-0001.
</content>
