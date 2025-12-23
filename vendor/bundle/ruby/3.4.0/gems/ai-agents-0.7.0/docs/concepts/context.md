---
layout: default
title: Context
parent: Concepts
nav_order: 3
---

# Context

**Context** is the serializable state management system that preserves information across agent interactions, tool executions, and handoffs. Context enables conversation continuity and cross-session persistence through a simple hash-based structure.

## Context Architecture

Context flows through multiple abstraction layers:

### User Context (Serializable)
The main context hash that persists across sessions:
```ruby
context = {
  user_id: 123,
  conversation_history: [...],
  current_agent: "Billing",
  state: { customer_tier: "premium" }  # Tools use this nested hash for persistent data
}
```

### RunContext (Execution Wrapper)
Wraps user context with execution-specific features:
- **Context Hash**: Shared data accessible to all tools and agents
- **Thread Safety**: Deep copying ensures execution isolation

### ToolContext (Tool-Specific View)
Provides tools with controlled access to execution state:
- **Context Access**: Read/write access to shared context hash
- **State Management**: Dedicated space for persistent tool state

## The `ToolContext`

The `ToolContext` is a wrapper around the `RunContext` that is passed to each tool when it is executed. It provides the tool with controlled access to the execution state, including the shared context hash.

By passing the context through the `ToolContext`, we ensure that tools can remain stateless and thread-safe, as they do not need to store any execution-specific state in their instance variables.

## Context Serialization

Context is fully serializable for persistence across process boundaries:

```ruby
# Run conversation
result = runner.run("Hello, I'm John")

# Serialize for storage
context_json = result.context.to_json
# Store in database, file, session, etc.

# Later: restore and continue
restored_context = JSON.parse(context_json, symbolize_names: true)
next_result = runner.run("What's my name?", context: restored_context)
# => "Your name is John"
```

## Conversation Continuity

The AgentRunner automatically manages conversation continuity through context:

```ruby
# Create runner
runner = Agents::Runner.with_agents(triage_agent, billing_agent)

# First interaction
result1 = runner.run("I need billing help")
# Triage agent hands off to billing agent
# Context includes: current_agent: "Billing"

# Continue conversation
result2 = runner.run("What payment methods do you accept?", context: result1.context)
# AgentRunner detects billing agent should continue based on context
```

## State Management

Tools can use the context for persistent state:

```ruby
class CustomerLookupTool < Agents::Tool
  def perform(tool_context, customer_id:)
    customer = Customer.find(customer_id)
    
    # Store in shared state for other tools
    tool_context.state[:customer_id] = customer_id
    tool_context.state[:customer_name] = customer.name
    tool_context.state[:account_type] = customer.account_type
    
    "Found customer: #{customer.name}"
  end
end

class BillingTool < Agents::Tool
  def perform(tool_context)
    # Access state from previous tool
    customer_id = tool_context.state[:customer_id]
    account_type = tool_context.state[:account_type]
    
    return "No customer found" unless customer_id
    
    # Use customer info for billing operations
    billing_info = get_billing_info(customer_id, account_type)
    billing_info.to_s
  end
end
```
