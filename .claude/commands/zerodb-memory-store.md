---
description: Store agent memory in ZeroDB for persistent context
---

Use the mcp__ainative-zerodb__zerodb_store_memory tool to store conversation memory.

Example usage:
- Persist agent conversation history
- Store user interactions for learning
- Build long-term memory systems

Key parameters:
- content: Memory content to store (required)
- role: Message role - "user", "assistant", or "system" (required)
- session_id: Session identifier (auto-generated if not provided)
- agent_id: Agent identifier (auto-generated if not provided)
- metadata: Additional metadata (optional)

Ask the user what memory to store, then use the tool to persist it.
