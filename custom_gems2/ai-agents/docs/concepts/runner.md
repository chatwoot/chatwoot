---
layout: default
title: Runner
parent: Concepts
nav_order: 5
---

# AgentRunner

The **AgentRunner** is the thread-safe execution manager that provides the main API for multi-agent conversations. It separates agent registry management from execution, enabling safe concurrent use across multiple threads while maintaining conversation continuity.

## Two-Tier Architecture

The library uses a two-tier design separating long-lived configuration from short-lived execution:

### AgentRunner (Thread-Safe Manager)
- Created once at application startup
- Maintains immutable agent registry
- Determines conversation continuity from history
- Thread-safe for concurrent conversations

### Runner (Internal Execution Engine)
- Created per conversation turn
- Handles LLM communication and tool execution
- Manages context state during execution
- Stateless and garbage-collected after use

## Conversation Flow

Each conversation follows this flow:

1. **Agent Selection**: AgentRunner determines current agent from conversation history
2. **Context Isolation**: Creates deep copy of context for thread safety
3. **LLM Communication**: Sends message with context to language model
4. **Tool Execution**: Executes any requested tools through RubyLLM
5. **Handoff Detection**: Checks for agent handoffs and switches if needed
6. **State Persistence**: Updates context with conversation state

## Thread Safety

The AgentRunner ensures thread safety through several key mechanisms:

*   **Immutable Registry**: Agent registry is frozen after initialization, preventing runtime modifications
*   **Context Isolation**: Each execution receives a deep copy of context to prevent cross-contamination
*   **Stateless Execution**: Internal Runner instances store no execution-specific state
*   **Tool Wrapping**: ToolWrapper injects context through parameters, keeping tools stateless

## Usage Pattern

Create an AgentRunner once and reuse it for multiple conversations:

```ruby
# Create agents
triage_agent = Agents::Agent.new(
  name: "Triage",
  instructions: "Route users to appropriate specialists"
)
billing_agent = Agents::Agent.new(
  name: "Billing", 
  instructions: "Handle billing inquiries"
)

# Register handoffs
triage_agent.register_handoffs(billing_agent)

# Create runner once (thread-safe)
runner = Agents::Runner.with_agents(triage_agent, billing_agent)

# Use from multiple threads safely
result1 = runner.run("I have a billing question")
result2 = runner.run("Follow up", context: result1.context)
```

## Conversation Continuity

The AgentRunner automatically maintains conversation continuity by analyzing message history to determine which agent should handle each turn:

```ruby
# First message -> Uses triage agent (default entry point)
result1 = runner.run("I need help with my bill")

# Triage hands off to billing agent
# Next message -> AgentRunner detects billing agent should continue
result2 = runner.run("What payment methods do you accept?", context: result1.context)
```

The `run` method returns a `RunResult` with output, messages, usage metrics, error status, and updated context.
