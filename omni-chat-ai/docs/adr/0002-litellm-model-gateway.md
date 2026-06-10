# ADR-0002: LiteLLM as the model gateway (no OpenAI lock-in)

- **Status:** Accepted
- **Date:** 2026-06-10

## Context
Requirement: "not tied to ChatGPT/OpenAI." We use managed APIs but must be able to swap
providers without touching agent code, and want one place for keys, cost caps, routing, fallback.

## Decision
Put **LiteLLM (MIT)** in front of all LLM calls. Agents call a stable alias (`claude-primary`)
over the OpenAI-compatible protocol. **Anthropic Claude is the default brain**; OpenAI/OpenRouter/
local are configured as fallbacks in `litellm/config.yaml`.

## Consequences
- (+) Provider swap = config change; transparent fallbacks; centralized spend/limits.
- (+) Works with Pydantic AI / LangGraph unchanged; Langfuse-native tracing.
- (−) One more hop/service to operate (acceptable; it's lightweight and stateless).

## Alternatives considered
- Call provider SDKs directly — couples code to a vendor; rejected.
- OpenRouter only — still a single external dependency; LiteLLM can use it as one backend.
