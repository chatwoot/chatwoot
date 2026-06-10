# Glossary

- **Unified Chat Panel** — the single inbox (Chatwoot) where every channel lands.
- **Agent Bot** — Chatwoot construct: a webhook-connected bot attached to an inbox. New
  conversations on a bot inbox start as `pending`.
- **Handoff (`bot_handoff!`)** — flipping conversation status `pending → open`; stops the bot,
  gives the conversation to a human. Reverse (`open → pending`) returns control to the bot.
- **Orchestrator** — the LangGraph supervisor that routes a message to a specialist agent.
- **Specialist agent** — a Pydantic AI typed agent (support / consultation / warranty / sales).
- **Model gateway** — LiteLLM; all LLM calls go through it (alias `claude-primary`).
- **Copilot mode** — AI drafts, human approves before send. **Autopilot mode** — AI replies directly.
- **RAG feedback loop** — re-indexing resolved answers into the KB; the real "self-learning".
- **Eval** — Langfuse traces + LLM-as-judge/code evaluators + Ragas/Promptfoo in CI.
