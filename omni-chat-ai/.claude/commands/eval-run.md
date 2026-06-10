---
description: Add or run an evaluation for the agents (Langfuse / Ragas / Promptfoo)
---

Set up or run evaluation for: **$ARGUMENTS**.

Follow ADR-0005 and the `eval-engineer` subagent's guidance:
1. Ensure the relevant turns are traced to Langfuse (instrument first; measure before changing).
2. Build/extend a dataset of representative conversations with expected outcomes.
3. Add evaluators: LLM-as-judge (faithfulness/correctness) and/or code evaluators (schema, tool
   args). For RAG, add Ragas faithfulness/answer-relevancy. For prompts, add a Promptfoo case.
4. Run as an experiment; compare scores against the baseline in Langfuse. Wire it into CI so a
   score drop fails the PR.
5. Do NOT propose RLHF/DPO or fact fine-tuning — prefer the RAG feedback loop + prompt iteration.
