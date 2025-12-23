---
layout: default
title: Building Multi-Agent Systems
parent: Guides
nav_order: 1
---

# Building Multi-Agent Systems

Multi-agent systems allow you to decompose complex problems into specialized agents that collaborate to provide comprehensive solutions. This guide covers patterns and best practices for designing effective multi-agent workflows.

## Core Patterns

### Hub-and-Spoke Architecture

The most common and stable pattern is hub-and-spoke, where a central triage agent routes conversations to specialized agents:

```ruby
# Specialized agents
billing_agent = Agents::Agent.new(
  name: "Billing",
  instructions: "Handle billing inquiries, payment processing, and account issues."
)

support_agent = Agents::Agent.new(
  name: "Support",
  instructions: "Provide technical troubleshooting and product support."
)

# Central hub agent
triage_agent = Agents::Agent.new(
  name: "Triage",
  instructions: "Route users to the appropriate specialist. Only hand off, don't solve problems yourself."
)

# Register handoffs (one-way: triage -> specialists)
triage_agent.register_handoffs(billing_agent, support_agent)

# Create runner with triage as entry point
runner = Agents::Runner.with_agents(triage_agent, billing_agent, support_agent)
```

### Dynamic Instructions

Use Proc-based instructions to create context-aware agents:

```ruby
support_agent = Agents::Agent.new(
  name: "Support",
  instructions: ->(context) {
    customer_tier = context[:customer_tier] || "standard"
    <<~INSTRUCTIONS
      You are a technical support specialist for #{customer_tier} tier customers.
      #{customer_tier == "premium" ? "Provide priority white-glove service." : ""}

      Available tools: diagnostics, escalation
    INSTRUCTIONS
  }
)
```

## Agent Design Principles

### Clear Boundaries

Each agent should have a distinct, non-overlapping responsibility:

```ruby
# GOOD: Clear specialization
sales_agent = Agents::Agent.new(
  name: "Sales",
  instructions: "Handle product inquiries, pricing, and purchase decisions. Transfer technical questions to support."
)

support_agent = Agents::Agent.new(
  name: "Support",
  instructions: "Handle technical issues and product troubleshooting. Transfer sales questions to sales team."
)
```

### Avoiding Handoff Loops

Design instructions to prevent infinite handoffs:

```ruby
# BAD: Conflicting handoff criteria
agent_a = Agents::Agent.new(
  instructions: "Handle X. If you need Y info, hand off to Agent B."
)
agent_b = Agents::Agent.new(
  instructions: "Handle Y. If you need X context, hand off to Agent A."
)

# GOOD: Clear escalation hierarchy
specialist = Agents::Agent.new(
  instructions: "Handle specialized requests. Ask users for needed info directly."
)
triage = Agents::Agent.new(
  instructions: "Route users to specialists. Don't solve problems yourself."
)
```

## Conversation Flow Management

### Entry Points

The first agent in `AgentRunner.with_agents()` becomes the default entry point:

```ruby
# Triage agent handles all initial conversations
runner = Agents::Runner.with_agents(triage_agent, billing_agent, support_agent)

# Start conversation
result = runner.run("I need help with my account")
# -> Automatically starts with triage_agent
```

### Context Preservation

The AgentRunner automatically maintains conversation history across handoffs:

```ruby
# First interaction
result1 = runner.run("My name is John and I have a billing question")
# -> Triage agent hands off to billing agent

# Continue conversation
result2 = runner.run("What payment methods do you accept?", context: result1.context)
# -> Billing agent remembers John's name and previous context
```

### Handoff Detection

The system automatically determines the current agent from conversation history:

```ruby
# No need to manually specify which agent to use
result = runner.run("Follow up question", context: previous_result.context)
# -> AgentRunner automatically selects correct agent based on conversation state
```

## Advanced Patterns

### Tool-Specific Agents

Create agents specialized for particular tool categories:

```ruby
data_agent = Agents::Agent.new(
  name: "DataAnalyst",
  instructions: "Analyze data and generate reports using available analytics tools.",
  tools: [DatabaseTool.new, ChartGeneratorTool.new, ReportTool.new]
)

communication_agent = Agents::Agent.new(
  name: "Communications",
  instructions: "Handle notifications and external communications.",
  tools: [EmailTool.new, SlackTool.new, SMSTool.new]
)
```

### Conditional Handoffs

Use dynamic instructions to control handoff behavior:

```ruby
triage_agent = Agents::Agent.new(
  name: "Triage",
  instructions: ->(context) {
    business_hours = context[:business_hours] || false

    base_instructions = "Route users to appropriate departments."

    if business_hours
      base_instructions + " All departments are available."
    else
      base_instructions + " Only hand off urgent technical issues to support. Others should wait for business hours."
    end
  }
)
```

## Testing Multi-Agent Systems

### Unit Testing Individual Agents

Test each agent in isolation:

```ruby
RSpec.describe "BillingAgent" do
  let(:agent) { create_billing_agent }
  let(:runner) { Agents::Runner.with_agents(agent) }

  it "handles payment inquiries" do
    result = runner.run("What payment methods do you accept?")
    expect(result.output).to include("credit card", "bank transfer")
  end
end
```

### Integration Testing Handoffs

Test complete workflows:

```ruby
RSpec.describe "Customer Support Workflow" do
  let(:runner) { create_support_runner } # Creates triage + specialists

  it "routes billing questions correctly" do
    result = runner.run("I have a billing question")

    # Verify handoff occurred
    expect(result.context[:current_agent]).to eq("Billing")

    # Test continued conversation
    followup = runner.run("What are your payment terms?", context: result.context)
    expect(followup.output).to include("payment terms")
  end
end
```

## Common Pitfalls

### Over-Specialization
Don't create too many narrow agents - it increases handoff complexity and latency.

### Under-Specified Instructions
Vague instructions lead to inappropriate handoffs. Be explicit about what each agent should and shouldn't handle.

### Circular Dependencies
Avoid mutual handoffs between agents. Use hub-and-spoke or clear hierarchical patterns instead.

### Context Leakage
Don't rely on shared mutable state. Use the context hash for inter-agent communication.

## Performance Considerations

### Handoff Overhead
Each handoff adds latency. Design agents to minimize unnecessary transfers.

### Context Size
Large contexts increase token usage. Clean up irrelevant data periodically:

```ruby
# Remove old conversation history
cleaned_context = result.context.dup
cleaned_context[:conversation_history] = cleaned_context[:conversation_history].last(10)
```

### Concurrent Execution
AgentRunner is thread-safe, allowing multiple conversations simultaneously:

```ruby
# Safe to use same runner across threads
threads = users.map do |user|
  Thread.new do
    user_result = runner.run(user.message, context: user.context)
    # Handle result...
  end
end
```
