---
layout: default
title: Custom Request Headers
parent: Guides
nav_order: 6
---

# Custom Request Headers

Custom HTTP headers allow you to pass additional metadata with your LLM API requests. This is useful for authentication, request tracking, A/B testing, and provider-specific features.

## Basic Usage

### Agent-Level Headers

Set default headers when creating an agent that will be applied to all requests:

```ruby
agent = Agents::Agent.new(
  name: "Assistant",
  instructions: "You are a helpful assistant",
  headers: {
    "X-Custom-ID" => "agent-123",
    "X-Environment" => "production"
  }
)

runner = Agents::Runner.with_agents(agent)
result = runner.run("Hello!")
# All requests will include the custom headers
```

### Runtime Headers

Override or add headers for specific requests:

```ruby
agent = Agents::Agent.new(
  name: "Assistant",
  instructions: "You are a helpful assistant"
)

runner = Agents::Runner.with_agents(agent)

# Pass headers at runtime
result = runner.run(
  "What's the weather?",
  headers: {
    "X-Request-ID" => "req-456",
    "X-User-ID" => "user-789"
  }
)
```

### Header precedence

When both agent-level and runtime headers are provided, **runtime headers take precedence**:

```ruby
agent = Agents::Agent.new(
  name: "Assistant",
  instructions: "You are a helpful assistant",
  headers: {
    "X-Environment" => "staging",
    "X-Agent-ID" => "agent-001"
  }
)

runner = Agents::Runner.with_agents(agent)

result = runner.run(
  "Hello!",
  headers: {
    "X-Environment" => "production",  # Overrides agent's staging value
    "X-Request-ID" => "req-123"       # Additional header
  }
)

# Final headers sent to LLM API:
# {
#   "X-Environment" => "production",  # Runtime value wins
#   "X-Agent-ID" => "agent-001",      # From agent
#   "X-Request-ID" => "req-123"       # From runtime
# }
```

## See Also

- [Multi-Agent Systems](multi-agent-systems.html) - Using headers across agent handoffs
- [Rails Integration](rails-integration.html) - Request tracking in Rails applications
- [State Persistence](state-persistence.html) - Combining headers with conversation state
