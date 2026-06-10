# ADR-0005: Langfuse-centred eval + RAG feedback loop for self-learning

- **Status:** Accepted
- **Date:** 2026-06-10

## Context
The system must "self-learn and self-evaluate." In production, model weights are frozen, so real
learning = retrieval + disciplined evaluation, not autonomous weight updates.

## Decision
- **Observability/eval hub:** **Langfuse v4 (MIT, self-hosted)** — traces, cost, LLM-as-judge,
  code evaluators, datasets, experiments in CI/CD, MCP.
- **RAG eval:** **Ragas** (faithfulness/answer-relevancy). **Prompt CI:** **Promptfoo**.
- **Self-learning (real):** a **RAG feedback loop** — resolved answers/articles are re-indexed
  into the KB so future answers improve. Business KPIs (AOV/conversion) pushed to Langfuse as scores.
- **Deferred:** Mem0 (per-customer memory), DSPy (prompt optimization), managed fine-tune (tone only).
- **Avoid early:** RLHF/DPO from manager feedback; fine-tuning for facts; "self-evolving agents".

## Consequences
- (+) Genuine, measurable improvement loop with small footprint; all OSS.
- (−) Requires discipline (datasets, judges) — start minimal, expand.

## Alternatives considered
- Phoenix/Helicone — viable; Langfuse picked for MIT + breadth (trace+eval+prompt+datasets).
- "Self-improving agent" frameworks — research-stage; rejected for v1.
