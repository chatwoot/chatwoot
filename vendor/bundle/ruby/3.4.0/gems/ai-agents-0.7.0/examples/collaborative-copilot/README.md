# Copilot Agents & Tools

This example demonstrates a collaborative multi-agent system for customer support, inspired by Chatwoot's copilot feature. The system uses the agent-as-tool pattern to enable specialized agents to work together behind the scenes.

## Agent Architecture Overview

The Chatwoot Copilot system consists of 4 specialized AI agents that work together to assist support agents with customer conversations.

```
┌─────────────────────────────────────────┐
│          Answer Suggestion Agent        │
│              (Primary Entry)            │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Research   │   │  Analysis   │   │Integration  │
│   Agent     │   │   Agent     │   │   Agent     │
└─────────────┘   └─────────────┘   └─────────────┘
```

---

## 1. Answer Suggestion Agent

**Primary Role**: Main interface for support agents seeking assistance

### Responsibilities:
- Serve as the primary entry point for all agent queries
- Provide direct answers and draft responses to customer inquiries
- Suggest appropriate solutions based on available knowledge
- Route complex queries to specialized agents when needed
- Synthesize information from multiple sources into actionable advice

### Tools Available:
- **GetConversationTool**: Retrieve current conversation details and context
- **GetContactTool**: Access customer profile and contact information
- **SearchDocumentationTool**: Search help documentation and guides
- **GetArticleTool**: Retrieve specific knowledge base articles
- **SearchArticlesTool**: Search across knowledge base content

### When Support Agents Use This:
- "What should I tell this customer?"
- "How do I handle this type of issue?"
- "What's the best response for this situation?"
- "Can you help me draft a reply?"

---

## 2. Research Agent

**Primary Role**: Deep investigation and historical analysis specialist

### Responsibilities:
- Investigate customer interaction history and patterns
- Find similar past cases and their resolutions
- Analyze customer behavior across multiple conversations
- Provide comprehensive context about customer relationships
- Identify recurring issues and successful resolution strategies

### Tools Available:
- **SearchConversationsTool**: Find similar past conversations and cases
- **SearchContactsTool**: Discover related customers and interaction patterns
- **GetContactTool**: Retrieve detailed customer profiles and history

### When Support Agents Use This:
- "What's this customer's history with us?"
- "How have we handled similar issues before?"
- "Are there patterns in this customer's behavior?"
- "What similar cases can help me understand this situation?"

---

## 3. Analysis Agent

**Primary Role**: Conversation quality and communication guidance specialist

### Responsibilities:
- Analyze conversation tone, sentiment, and emotional state
- Assess conversation health and progress toward resolution
- Provide communication guidance and tone recommendations
- Evaluate customer satisfaction indicators
- Suggest conversation management strategies

### Tools Available:
- **GetConversationTool**: Analyze current conversation state and progression

### When Support Agents Use This:
- "How is this conversation going?"
- "What's the customer's mood/sentiment?"
- "How should I adjust my communication approach?"
- "Is this conversation escalating or improving?"
- "What tone should I use in my response?"

---

## 4. Integrations Agent

**Primary Role**: External systems and technical context specialist

### Responsibilities:
- Provide technical context from development and project management tools
- Access external system data relevant to customer issues
- Retrieve billing and subscription information (future)
- Connect customer issues with known bugs or feature requests
- Bridge customer support with engineering and product teams

### Tools Available:
- **SearchLinearIssuesTool**: Search Linear issues for development context and bug reports

### Future Tools (Planned):
- **GitHubSearchTool**: Repository search for technical context
- **StripeBillingTool**: Billing and subscription information
- **SlackIntegrationTool**: Team communication context

### When Support Agents Use This:
- "Is this a known technical issue?"
- "Are there any related bug reports?"
- "What's the development status of this feature?"
- "Is there billing information relevant to this case?"

---

## Usage Example

```ruby
# Create the main answer suggestion agent with sub-agents as tools
answer_agent = Agents::Agent.new(
  name: "AnswerSuggestionAgent",
  instructions: "You help support agents by providing answers and suggestions...",
  tools: [
    research_agent.as_tool(
      name: "research_customer_history",
      description: "Research customer history and similar cases"
    ),
    analysis_agent.as_tool(
      name: "analyze_conversation",
      description: "Analyze conversation tone and sentiment"
    ),
    integrations_agent.as_tool(
      name: "check_technical_context",
      description: "Check for technical issues and development context"
    )
  ]
)

# Support agent asks for help
result = runner.run(answer_agent, "How should I respond to this angry customer about login issues?")
```

## Key Features

- **Agent-as-Tool Pattern**: Sub-agents work behind the scenes, no conversation handoffs
- **Specialized Expertise**: Each agent focuses on specific domain knowledge
- **State Sharing**: Agents share context through the state mechanism
- **Composable Architecture**: Easy to add new specialized agents
- **Thread-Safe**: Safe for concurrent support agent usage

## Running the Example

```bash
# Set your API key
export OPENAI_API_KEY="your-key-here"

# Run the interactive demo
ruby examples/collaborative-copilot/interactive.rb
```
