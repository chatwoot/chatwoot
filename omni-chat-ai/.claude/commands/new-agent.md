---
description: Scaffold a new AI specialist agent (Pydantic AI node in the LangGraph graph)
---

Create a new specialist agent named **$ARGUMENTS** for Omni-Chat-AI.

Follow the project rules in `CLAUDE.md` and the pattern in `ai-service/app/agents/support.py`:

1. Create `ai-service/app/agents/$ARGUMENTS.py`:
   - a Pydantic AI `Agent` over the LiteLLM model (`settings.agent_model`),
   - a typed `output_type` (include `needs_human` + `handoff_reason`),
   - a focused `system_prompt` for this specialty,
   - typed `@agent.tool_plain` tools it needs (reuse `app/tools/` where possible).
2. Add a node + edge in `ai-service/app/graph.py` and a branch in `route()` so the supervisor
   can route to it.
3. Add a smoke test in `ai-service/tests/`.
4. If the specialty introduces a new architectural choice, add an ADR via `/new-adr`.

Keep it minimal and typed. Report the commands to run (`pytest`, `ruff check ai-service`).
