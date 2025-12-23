---
layout: default
title: Architecture
nav_order: 4
published: false
---

# Architecture

The AI Agents library is designed around key principles of immutability, thread safety, and separation of concerns. This architecture enables scalable multi-agent systems that can handle concurrent conversations while maintaining state consistency.

## Core Architecture Principles

### Immutability by Design
- **Agents are immutable** once created, preventing configuration drift
- **Context is deep-copied** for each execution to prevent cross-contamination
- **Registry is frozen** after initialization to prevent runtime modifications

### Thread Safety
- **No shared mutable state** between concurrent executions
- **Context isolation** through deep copying and closure capture
- **Stateless tool design** with context injection via parameters

### Separation of Concerns
- **Agent definition** (configuration) vs **Agent execution** (runtime)
- **Tool functionality** vs **Tool context** (execution state)
- **Conversation orchestration** vs **LLM communication**

## Component Architecture

### Two-Tier Execution Model

The library uses a two-tier architecture separating long-lived configuration from short-lived execution:

```
┌─────────────────┐    ┌─────────────────┐
│   AgentRunner   │    │     Runner      │
│   (Long-lived)  │────▶│  (Per-request)  │
│                 │    │                 │
│ • Agent Registry│    │ • Execution     │
│ • Entry Point   │    │ • Context Mgmt  │
│ • Thread Safety │    │ • Handoff Logic │
└─────────────────┘    └─────────────────┘
```

**AgentRunner** (Thread-Safe Manager):
- Created once, reused for multiple conversations
- Maintains immutable agent registry
- Determines conversation continuity
- Thread-safe for concurrent use

**Runner** (Execution Engine):
- Created per conversation turn
- Handles LLM communication and tool execution
- Manages context state during execution
- Stateless and garbage-collected after use

### Context Management Architecture

Context flows through multiple abstraction layers:

```
┌─────────────────┐
│   User Context  │ (Serializable across sessions)
│                 │
├─────────────────┤
│   RunContext    │ (Execution isolation)
│                 │
├─────────────────┤
│   ToolContext   │ (Tool-specific state)
│                 │
└─────────────────┘
```

**User Context**: Serializable hash for persistence
**RunContext**: Execution wrapper with usage tracking
**ToolContext**: Tool-specific view with retry metadata

## Handoff Architecture

### Tool-Based Handoff System

Handoffs are implemented as specialized tools rather than instruction-parsing:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Triage Agent  │    │  HandoffTool    │    │  Billing Agent  │
│                 │    │                 │    │                 │
│ • Instructions  │────▶│ • Target Agent  │────▶│ • Instructions  │
│ • Handoff List  │    │ • Schema        │    │ • Specialized   │
│ • General Role  │    │ • Execution     │    │ • Tools         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Benefits of Tool-Based Handoffs**:
- **Reliable invocation**: LLMs consistently use tools when available
- **Clear semantics**: Tool schema explicitly defines handoff criteria
- **No text parsing**: Eliminates need to parse free-form responses
- **Provider agnostic**: Works consistently across OpenAI, Anthropic, etc.

### First-Call-Wins Handoff Resolution

To prevent infinite handoff loops, the system implements first-call-wins semantics:

```
LLM Response with Multiple Handoffs:
┌─────────────────────────────────────┐
│ Call 1: handoff_to_support()       │ ✓ Processed
│ Call 2: handoff_to_billing()       │ ✗ Ignored
│ Call 3: handoff_to_support()       │ ✗ Ignored
└─────────────────────────────────────┘
Result: Transfer to Support Agent only
```

This mirrors OpenAI's SDK behavior and prevents conflicting handoff states.

## Thread Safety Implementation

### Context Isolation Pattern

Each execution receives an isolated context copy:

```ruby
# Thread-safe execution flow
def run(input, context: {})
  # 1. Deep copy context for isolation
  context_copy = deep_copy_context(context)

  # 2. Create execution wrapper
  run_context = RunContext.new(context_copy)

  # 3. Execute with isolated state
  result = execute_with_context(run_context)

  # 4. Return serializable result
  return result
end
```

### Tool Wrapper Pattern

Tools remain stateless through the wrapper pattern:

```ruby
# Tool Definition (Stateless)
class WeatherTool < Agents::Tool
  def perform(tool_context, city:)
    api_key = tool_context.context[:weather_api_key]
    WeatherAPI.get(city, api_key)
  end
end

# Runtime Wrapping (Context Injection)
wrapped_tool = ToolWrapper.new(weather_tool, context_wrapper)
```

The wrapper captures context in its closure, injecting it during execution without modifying the tool instance.

## Chat Architecture

### Extended Chat System

The library extends RubyLLM::Chat with handoff detection:

```
┌─────────────────┐    ┌─────────────────┐
│   Agents::Chat  │    │  RubyLLM::Chat  │
│   (Extended)    │────▶│   (Base)        │
│                 │    │                 │
│ • Handoff Detect│    │ • LLM Comm      │
│ • Tool Classify │    │ • Tool Execution│
│ • First-Call-Wins│   │ • Message Mgmt  │
└─────────────────┘    └─────────────────┘
```

**Handoff Detection Flow**:
1. Classify tool calls into handoff vs regular tools
2. Execute first handoff only (first-call-wins)
3. Return HandoffResponse to signal agent switch
4. Execute regular tools normally with continuation

### Conversation Continuity

The system maintains conversation state through message attribution:

```ruby
# Messages include agent attribution
{
  role: :assistant,
  content: "I can help with billing",
  agent_name: "Billing"  # Enables conversation continuity
}
```

AgentRunner uses this attribution to determine conversation ownership when resuming.

## Provider Abstraction

### RubyLLM Integration

The library builds on RubyLLM for provider abstraction:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Agents     │    │    RubyLLM      │    │   Providers     │
│                 │    │                 │    │                 │
│ • Multi-Agent   │────▶│ • Unified API   │────▶│ • OpenAI        │
│ • Handoffs      │    │ • Tool Calling  │    │ • Anthropic     │
│ • Context Mgmt  │    │ • Streaming     │    │ • Gemini        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

This abstraction allows switching between providers without changing agent logic.

## State Management

### Context Serialization

The entire conversation state is serializable:

```ruby
# Serialize context for persistence
context_json = result.context.to_json

# Restore and continue conversation
restored_context = JSON.parse(context_json, symbolize_names: true)
next_result = runner.run("Continue conversation", context: restored_context)
```

**Serialization includes**:
- Conversation history with agent attribution
- Current agent state
- Tool-specific state
- User-defined context data

### State Persistence Patterns

The library supports multiple persistence patterns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   In-Memory     │    │   File-Based    │    │   Database      │
│                 │    │                 │    │                 │
│ • Development   │    │ • Simple Deploy │    │ • Production    │
│ • Testing       │    │ • Single Server │    │ • Multi-Server  │
│ • Rapid Iteration│   │ • File Storage  │    │ • ActiveRecord  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

All patterns use the same serialization format for consistency.

## Performance Characteristics

### Memory Management

- **Immutable objects** are shared safely across threads
- **Context copies** are garbage-collected after execution
- **Tool instances** are reused without state accumulation

### Execution Efficiency

- **Minimal object creation** during execution
- **Direct LLM communication** without additional abstractions
- **Efficient handoff detection** through tool classification

### Scalability

- **Thread-safe design** enables horizontal scaling
- **Stateless execution** supports load balancing
- **Serializable state** enables process migration

## Error Handling Architecture

### Graceful Degradation

The system handles errors at multiple levels:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Agent Level   │    │   Tool Level    │    │   LLM Level     │
│                 │    │                 │    │                 │
│ • Handoff Fails │    │ • Tool Errors   │    │ • API Errors    │
│ • Max Turns     │    │ • Retry Logic   │    │ • Rate Limits   │
│ • State Errors  │    │ • Fallback      │    │ • Timeouts      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Error Recovery

- **Context preservation** even during errors
- **Partial execution results** for debugging
- **Conversation continuity** after error resolution

## Extension Points

### Custom Tools

The tool system is fully extensible:

```ruby
class CustomTool < Agents::Tool
  name "custom_action"
  description "Perform custom business logic"
  param :input, type: "string"

  def perform(tool_context, input:)
    # Access context for state
    user_id = tool_context.context[:user_id]

    # Perform custom logic
    result = BusinessLogic.process(input, user_id)

    # Update shared state
    tool_context.state[:last_action] = result

    result
  end
end
```

### Custom Providers

While built on RubyLLM, the architecture supports custom providers:

```ruby
# Custom provider integration
class CustomProvider < RubyLLM::Provider
  def complete(messages, **options)
    # Custom LLM integration
  end
end

# Use with agents
agent = Agents::Agent.new(
  name: "Assistant",
  model: CustomProvider.new.model("custom-model")
)
```

### Debug Hooks

The system provides hooks for debugging and tracing:

```ruby
# Enable debug logging
ENV["RUBYLLM_DEBUG"] = "true"

# Custom callbacks
chat.on(:new_message) { puts "Sending to LLM..." }
chat.on(:end_message) { |response| puts "Received: #{response.content}" }
```

This architecture provides a robust foundation for building production-ready multi-agent systems while maintaining simplicity and developer productivity.
