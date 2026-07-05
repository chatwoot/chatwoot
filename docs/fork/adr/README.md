# Architecture Decision Records (Chatwoot fork)

These ADRs record the **load-bearing decisions** that govern how this Chatwoot
fork integrates with the external platform (Next.js dashboard, NestJS control
plane, LangGraph orchestrator). They are authoritative for **both** repositories:
when the two sides disagree, the ADR wins, and the loser changes.

## Scope & relationship to the meta-saas ADRs

The external monorepo (meta-saas) keeps its own ADRs in
`docs/architecture/DECISIONS.md` (ADR-0014 "Meta-direct", superseded by ADR-0015
"automation control plane"). **Those numbers belong to that repo.** The ADRs here
are the **Chatwoot-fork side** of the same decisions and use their own `ADR-00xx`
sequence. Where a decision spans both repos, the ADR cross-references the
meta-saas number explicitly.

| Fork ADR | Title | Mirrors / relates to |
| --- | --- | --- |
| [ADR-0001](./0001-chatwoot-single-messaging-gateway.md) | Chatwoot is the single messaging gateway | meta-saas ADR-0015 |
| [ADR-0002](./0002-agentbot-canonical-ai-identity.md) | ~~System-managed AgentBot is the canonical AI reply identity~~ | **Superseded by ADR-0006** |
| [ADR-0003](./0003-webhook-subscription-set.md) | Webhook subscription set: `message_created` + `conversation_status_changed` | fixes the `conversation_resolved` subscription bug |
| [ADR-0004](./0004-external-agentic-ai-enforcement.md) | The agentic-AI usage cap is enforced externally; Chatwoot only displays it | meta-saas quota/usage metering |
| [ADR-0005](./0005-platform-managed-resources.md) | Platform-managed resources are excluded from tenant entitlements | resolves ADR-0002 open item |
| [ADR-0006](./0006-ai-reply-identity-platform-managed-agent-user.md) | AI reply identity is a platform-managed `role: agent` account_user (no AgentBot) | supersedes ADR-0002; builds on ADR-0005 |

## Format

Each ADR uses the standard `Context / Decision / Consequences` structure with a
`Status` line. Statuses: `Proposed`, `Accepted`, `Superseded by ADR-xxxx`.
Once `Accepted`, an ADR is immutable — supersede it with a new one rather than
editing the decision.
</content>
</invoke>
