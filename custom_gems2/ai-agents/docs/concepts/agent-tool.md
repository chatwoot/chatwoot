---
layout: default
title: AgentTool
parent: Concepts
nav_order: 6
---

# AgentTool

The `AgentTool` class enables **agent-to-agent collaboration** by wrapping agents as callable tools. This pattern allows specialized agents to work behind the scenes to help each other without conversation handoffs.

## Key Concept

Unlike handoffs where control transfers between agents with full conversation context, AgentTool creates **constrained execution environments** where wrapped agents:

- Cannot perform handoffs (empty registry)
- Have limited turn counts to prevent infinite loops
- Only receive shared state, not conversation history
- Always return control to the calling agent

## Architecture

```ruby
# Specialized agents as tools
research_agent = Agent.new(
  name: "Research Agent",
  instructions: "Research topics and extract key information"
)

analysis_agent = Agent.new(
  name: "Analysis Agent",
  instructions: "Analyze data and provide insights"
)

# Main orchestrator uses other agents as tools
orchestrator = Agent.new(
  name: "Orchestrator",
  instructions: "Coordinate research and analysis",
  tools: [
    research_agent.as_tool(
      name: "research_topic",
      description: "Research a specific topic"
    ),
    analysis_agent.as_tool(
      name: "analyze_data",
      description: "Analyze research findings"
    )
  ]
)
```

## Implementation Details

### Constraints

AgentTool implements several safety constraints:

1. **No Handoffs**: Wrapped agents receive an empty registry, preventing handoff calls
2. **Limited Turns**: Maximum 3 turns to prevent infinite loops
3. **Context Isolation**: Only shared state is passed, not conversation history
4. **Return Control**: Always returns to the calling agent

### Context Isolation

```ruby
# Parent context (full conversation state)
parent_context = {
  state: { user_id: 123, session: "abc" },
  conversation_history: [...],
  current_agent: "MainAgent",
  turn_count: 5
}

# Isolated context (only state)
isolated_context = {
  state: { user_id: 123, session: "abc" }
}
```

### Error Handling

AgentTool provides robust error handling:

- Execution failures return descriptive error messages
- Runtime exceptions are caught and reported
- Missing output is handled gracefully

## Usage Patterns

### Customer Support Copilot

```ruby
# Specialized agents for different domains
conversation_analyzer = Agent.new(
  name: "ConversationAnalyzer",
  instructions: "Extract order IDs and customer intent"
)

shopify_agent = Agent.new(
  name: "ShopifyAgent",
  instructions: "Perform Shopify operations",
  tools: [shopify_refund_tool, shopify_lookup_tool]
)

# Main copilot coordinates specialized agents
copilot = Agent.new(
  name: "SupportCopilot",
  instructions: "Help support agents with customer requests",
  tools: [
    conversation_analyzer.as_tool(
      name: "analyze_conversation",
      description: "Extract key information from conversation"
    ),
    shopify_agent.as_tool(
      name: "shopify_action",
      description: "Perform Shopify operations"
    )
  ]
)
```

## Output Transformation

AgentTool supports custom output extractors for transforming results:

```ruby
# Custom output extraction
summarizer = Agent.new(
  name: "Summarizer",
  instructions: "Summarize long content"
)

summarizer_tool = summarizer.as_tool(
  name: "summarize",
  description: "Create a summary",
  output_extractor: ->(result) {
    "SUMMARY: #{result.output&.first(200)}..."
  }
)
```

## Best Practices

1. **Keep it Simple**: Use AgentTool for focused, single-purpose tasks
2. **Avoid Deep Nesting**: Don't create agents that use agents that use agents
3. **State Management**: Only share necessary state between agents
4. **Error Handling**: Always handle potential execution failures
5. **Performance**: Consider the overhead of multiple agent calls

## Comparison with Handoffs

| Aspect | AgentTool | Handoff |
|--------|-----------|---------|
| **Purpose** | Behind-the-scenes collaboration | User-facing conversation transfer |
| **Context** | Isolated (state only) | Full conversation history |
| **Control** | Returns to caller | Transfers to target |
| **Constraints** | Limited turns, no handoffs | Full agent capabilities |
| **Use Case** | Internal processing | Conversation routing |

## See Also

<!-- - [Agent-as-Tool Pattern Guide](../guides/agent-as-tool-pattern.html)
- [Multi-Agent Systems](../guides/multi-agent-systems.html) -->

- [Tools Concept](tools.html)
- [Handoffs Concept](handoffs.html)
