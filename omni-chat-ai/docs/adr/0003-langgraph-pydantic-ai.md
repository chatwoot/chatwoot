# ADR-0003: LangGraph orchestrator + Pydantic AI in-node agents

- **Status:** Accepted
- **Date:** 2026-06-10

## Context
We need multi-agent routing (support/consultation/warranty/sales), clean human handoff, durable
multi-turn state, and typed tool calls into KeyCRM. Chatwoot already owns conversation state and
the human-pause, so the agent layer can be largely event-driven.

## Decision
Adopt the 2026 production pattern: **LangGraph (MIT library)** as the orchestrator/supervisor
(routing, escalation edges, optional Postgres checkpointer, native `interrupt()` HITL), with
**Pydantic AI (MIT)** typed agents running *inside* the nodes (validated I/O, typed CRM tools).
**DeepAgents** is reserved for deep back-office tasks only; **Agent Zero** rejected for
customer-facing use (autonomous OS/code-exec = wrong shape + safety surface).

## Consequences
- (+) Deterministic, auditable routing + typed tools; scales from one agent to a graph.
- (+) Provider-agnostic via LiteLLM; both libs MIT.
- (−) Two libraries to learn. Mitigation: start with one support agent, grow the graph.
- (★) Use the **MIT `langgraph` library only** — avoid the Elastic-licensed `langgraph-api`/Platform.

## Alternatives considered
- Pydantic AI alone — simplest, but multi-agent routing/HITL graph is lighter; we want the graph.
- LangGraph alone — fine, but Pydantic AI gives cleaner typed tools inside nodes.
- CrewAI/Autogen — fragile/maintenance-churn in production; rejected.
