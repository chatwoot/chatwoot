---
layout: default
title: Agent-as-Tool Pattern
parent: Guides
nav_order: 4
---

# Agent-as-Tool Pattern Guide

The Agent-as-Tool pattern enables **multi-agent collaboration** where specialized agents work behind the scenes to help each other, without the user knowing multiple agents are involved.

## When to Use This Pattern

Use Agent-as-Tool when you need:

- **Specialized Processing**: Different agents excel at different tasks
- **Behind-the-Scenes Coordination**: Agents collaborate invisibly to the user
- **Multi-step Workflows**: Complex processes requiring different expertise
- **Modular Architecture**: Clean separation of concerns between agents

## Core Concept

### Handoffs vs Agent-as-Tool

**Handoffs**: "Let me transfer you to billing"
- User-visible conversation transfer
- Full context shared
- Agent takes over conversation

**Agent-as-Tool**: "Let me check that for you" (uses billing agent internally)
- Invisible to user
- Limited context (state only)
- Returns control to caller

## Basic Implementation

### Step 1: Create Specialized Agents

```ruby
# Research agent - finds customer information
research_agent = Agents::Agent.new(
  name: "ResearchAgent",
  instructions: <<~PROMPT
    You research customer information and history.
    Return contact details including email addresses.
  PROMPT,
  tools: [customer_lookup_tool, conversation_search_tool]
)

# Billing agent - handles payment operations
billing_agent = Agents::Agent.new(
  name: "BillingAgent",
  instructions: <<~PROMPT
    You handle billing operations using Stripe.
    CRITICAL: You need customer email addresses for billing lookups.
    Contact IDs will NOT work.
  PROMPT,
  tools: [stripe_billing_tool]
)
```

### Step 2: Create Orchestrator with Agent Tools

```ruby
# Main agent coordinates specialists
orchestrator = Agents::Agent.new(
  name: "SupportCopilot",
  instructions: <<~PROMPT
    You help support agents by coordinating specialist agents.

    **CRITICAL: Multi-Step Workflow Approach**

    For complex queries, break them into steps and use tools sequentially:
    1. Plan your approach: What information do you need?
    2. Execute sequentially: Use EXACT results from previous tools
    3. Build context progressively: Each tool builds on previous findings

    **Tool Requirements:**
    - research_customer: Returns contact details including emails
    - check_billing: Requires customer email (not contact ID)

    Always think: "What did I learn and how do I use it next?"
  PROMPT,
  tools: [
    research_agent.as_tool(
      name: "research_customer",
      description: "Research customer details. Returns contact info including email."
    ),
    billing_agent.as_tool(
      name: "check_billing",
      description: "Check billing status. Requires customer email address."
    )
  ]
)
```

### Step 3: Use with Context Persistence

```ruby
# Set up runner with context persistence
runner = Agents::Runner.with_agents(orchestrator)
context = {}

# Interactive loop maintains context
loop do
  user_input = gets.chomp
  break if user_input == "exit"

  # Pass and update context each turn
  result = runner.run(user_input, context: context)
  context = result.context if result.context

  puts result.output
end
```

## Advanced Features

### Custom Output Extraction

Extract specific information for other tools:

```ruby
research_agent.as_tool(
  name: "get_customer_email",
  description: "Get customer email address",
  output_extractor: ->(result) {
    # Extract just the email instead of full response
    email_match = result.output.match(/Email:\s*([^\s]+)/i)
    email_match&.captures&.first || "Email not found"
  }
)
```

## Best Practices

### 1. Clear Tool Descriptions with Requirements

Specify what each tool needs and provides:

```ruby
# Good: Clear requirements
billing_agent.as_tool(
  name: "check_stripe_billing",
  description: "Check Stripe billing info. Requires customer email (not contact ID)."
)

research_agent.as_tool(
  name: "research_customer",
  description: "Research customer details. Returns email address and contact info."
)

# Avoid: Vague descriptions
agent.as_tool(name: "process", description: "Do stuff")
```

### 2. Multi-Step Workflow Instructions

Guide orchestrators to chain tool calls properly:

```ruby
orchestrator = Agent.new(
  instructions: <<~PROMPT
    **For complex queries requiring multiple pieces of information:**

    1. Plan what information you need to gather
    2. Use tools sequentially, building on previous results
    3. Extract specific values from tool outputs for subsequent calls
    4. Don't pass original parameters - use discovered values

    **Example:** To check billing for CONTACT-123:
    Step 1: research_customer("Get details for CONTACT-123") → finds email
    Step 2: check_billing("Check billing for [discovered email]") → not original ID
  PROMPT
)
```

### 3. Explicit Parameter Requirements in Agent Instructions

Make tool parameter needs crystal clear:

```ruby
billing_agent = Agent.new(
  instructions: <<~PROMPT
    **CRITICAL: Billing Requirements**
    - Stripe billing lookups REQUIRE customer email addresses
    - Contact IDs, names, phone numbers will NOT work
    - If you don't have email, clearly state you need it
  PROMPT
)
```

### 4. Handle Errors with Guidance

Provide helpful error messages that guide next steps:

```ruby
# In orchestrator instructions
instructions = <<~PROMPT
  **Error Handling:**
  - If billing fails due to missing email: Use research_customer first
  - If contact not found: Ask for more identifying information
  - Always provide helpful responses even if tools fail
PROMPT
```

### 5. Context Persistence for Multi-Turn Conversations

Maintain state across conversation turns:

```ruby
# Maintain context between interactions
runner = Agents::Runner.with_agents(orchestrator)
context = {}

# Each turn builds on previous context
result = runner.run(user_input, context: context)
context = result.context if result.context
```

### 6. Design Focused Agents

Keep agent responsibilities clear and narrow:

```ruby
# Good: Focused responsibility
customer_agent = Agent.new(
  name: "CustomerAgent",
  instructions: "Handle customer data lookups and history research"
)

# Avoid: Too broad
everything_agent = Agent.new(
  name: "EverythingAgent",
  instructions: "Handle all customer operations, billing, support, and analysis"
)
```

## See Also

- [AgentTool Concept](../concepts/agent-tool.html)
- [Multi-Agent Systems Guide](multi-agent-systems.html)
