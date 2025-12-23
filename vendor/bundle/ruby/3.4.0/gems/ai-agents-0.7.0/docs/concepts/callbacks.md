---
layout: default
title: Callbacks
parent: Concepts
nav_order: 6
---

# Real-time Callbacks

The AI Agents SDK provides real-time callbacks that allow you to monitor agent execution as it happens. This is particularly useful for building user interfaces that show live feedback about what agents are doing.

## Available Callbacks

The SDK provides seven types of callbacks that give you visibility into different stages of agent execution:

**Run Start** - Triggered before agent execution begins. Receives the agent name, input message, and run context.

**Run Complete** - Called after agent execution ends (whether successful or failed). Receives the agent name, result object, and run context.

**Agent Complete** - Triggered after each agent turn finishes. Receives the agent name, result, error (if any), and run context.

**Agent Thinking** - Triggered when an agent is about to make an LLM call. Useful for showing "thinking" indicators in UIs.

**Tool Start** - Called when an agent begins executing a tool. Shows which tool is being used and with what arguments.

**Tool Complete** - Triggered when a tool finishes execution. Provides the tool name and result for status updates.

**Agent Handoff** - Called when control transfers between agents. Shows the source agent, target agent, and handoff reason.

## Basic Usage

Callbacks are registered on the AgentRunner using chainable methods:

```ruby
runner = Agents::Runner.with_agents(triage, support)
  .on_run_start { |agent, input, ctx| puts "Starting: #{agent}" }
  .on_run_complete { |agent, result, ctx| puts "Completed: #{agent}" }
  .on_agent_complete { |agent, result, error, ctx| puts "Agent done: #{agent}" }
  .on_agent_thinking { |agent, input| puts "#{agent} thinking..." }
  .on_tool_start { |tool, args| puts "Using #{tool}" }
  .on_tool_complete { |tool, result| puts "#{tool} completed" }
  .on_agent_handoff { |from, to, reason| puts "#{from} → #{to}" }
```

## Integration Patterns

### UI Feedback

Callbacks work well with real-time web frameworks like Rails ActionCable, allowing you to stream agent status updates directly to browser clients:

```ruby
runner = Agents::Runner.with_agents(agent)
  .on_agent_thinking { |agent, input|
    ActionCable.server.broadcast("agent_#{user_id}", { type: 'thinking', agent: agent })
  }
  .on_tool_start { |tool, args|
    ActionCable.server.broadcast("agent_#{user_id}", { type: 'tool', name: tool })
  }
```

### Logging & Metrics

Callbacks are also useful for structured logging and metrics collection:

```ruby
runner = Agents::Runner.with_agents(agent)
  .on_run_start { |agent, input, ctx| logger.info("Run started", agent: agent) }
  .on_tool_start { |tool, args| metrics.increment("tool.calls", tags: ["tool:#{tool}"]) }
  .on_agent_complete do |agent, result, error, ctx|
    logger.error("Agent failed", agent: agent, error: error) if error
  end
```

## Thread Safety

Callbacks execute synchronously in the same thread as agent execution. Exceptions in callbacks are caught and logged as warnings without interrupting agent operation. For heavy operations or external API calls, consider using background jobs triggered by the callbacks.
