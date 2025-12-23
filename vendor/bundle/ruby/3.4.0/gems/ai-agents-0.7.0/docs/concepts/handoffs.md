---
layout: default
title: Handoffs
parent: Concepts
nav_order: 4
---

# Handoffs

**Handoffs** are a powerful feature of the Ruby Agents library that allow you to build sophisticated multi-agent systems. A handoff is the process of transferring a conversation from one agent to another, more specialized agent.

This is particularly useful when you have a general-purpose agent that can handle a wide range of queries, but you also have specialized agents that are better equipped to handle specific tasks. For example, you might have a triage agent that routes users to a billing agent or a technical support agent.

## How Handoffs Work

Handoffs are implemented as a special type of tool called a `HandoffTool`. When you configure an agent with `handoff_agents`, the library automatically creates a `HandoffTool` for each of the specified agents.

Here's how the handoff process works:

1.  **The user sends a message:** The user sends a message that indicates they need help with a specific task (e.g., "I have a problem with my bill").
2.  **The LLM decides to hand off:** The current agent's language model determines that the query is best handled by another agent and decides to call the corresponding `HandoffTool`.
3.  **The `HandoffTool` signals the handoff:** The `HandoffTool` sets a `pending_handoff` flag in the `RunContext`, indicating which agent to hand off to.
4.  **The Runner switches agents:** The `Runner` detects the `pending_handoff` flag and switches the `current_agent` to the new agent.
5.  **The conversation continues:** The conversation continues with the new agent, which now has access to the full conversation history.

### Loop Prevention

To prevent infinite handoff loops, the library automatically processes only the first handoff tool call in any LLM response. If multiple handoff tools are called in a single response, only the first one is executed and subsequent calls are ignored. This prevents conflicting handoff states and ensures clean agent transitions.

## Why Use Tools for Handoffs?

Using tools for handoffs has several advantages over simply instructing the LLM to hand off the conversation:

*   **Reliability:** LLMs are very good at using tools when they are available. By representing handoffs as tools, we can be more confident that the LLM will use them when appropriate.
*   **Clarity:** The tool's schema clearly defines when each handoff is suitable, making it easier for the LLM to make the right decision.
*   **Simplicity:** We don't need to parse free-text responses from the LLM to determine if a handoff is needed.
*   **Consistency:** This approach works consistently across different LLM providers.

## Example

```ruby
# Create the specialized agents
billing_agent = Agents::Agent.new(name: "Billing", instructions: "Handle billing and payment issues.")
support_agent = Agents::Agent.new(name: "Support", instructions: "Provide technical support.")

# Create the triage agent with handoff agents
triage_agent = Agents::Agent.new(
  name: "Triage",
  instructions: "You are a triage agent. Your job is to route users to the correct department.",
  handoff_agents: [billing_agent, support_agent]
)

# Run the triage agent
result = Agents::Runner.run(triage_agent, "I have a problem with my bill.")

# The runner will automatically hand off to the billing agent
```

In this example, the `triage_agent` will automatically hand off the conversation to the `billing_agent` when the user asks a question about their bill. This allows you to create a seamless user experience where the user is always talking to the most qualified agent for their needs.

## Troubleshooting Handoffs

### Infinite Handoff Loops

**Problem:** Agents keep handing off to each other in an endless loop.

**Common Causes:**
- Agent instructions that conflict with each other
- Agents configured to hand off for overlapping scenarios
- Poor instruction clarity about when to hand off vs. when to handle directly

**Solutions:**
1. **Review agent instructions:** Ensure each agent has a clear, distinct responsibility
2. **Use hub-and-spoke pattern:** Have specialized agents only hand off back to a central triage agent
3. **Add specific scenarios:** Include examples in instructions of when to handle vs. hand off
4. **Enable debug logging:** Use `ENV["RUBYLLM_DEBUG"] = "true"` to see handoff decisions


### Multiple Handoffs in One Response

The library automatically handles cases where an LLM tries to call multiple handoff tools in a single response. Only the first handoff will be processed, and subsequent calls will be ignored. This is normal behavior and prevents conflicting handoff states.
