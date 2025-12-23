# ISP Customer Support Demo

This example demonstrates a multi-agent customer support system for an Internet Service Provider (ISP). It showcases how specialized agents can work together to handle various customer requests through intelligent routing and handoffs.

## Architecture

The system uses a **hub-and-spoke pattern** with a triage agent that routes customers to appropriate specialists:

### Agents

1. **Triage Agent** - Entry point that greets customers and routes them to specialists
2. **Sales Agent** - Handles new customer acquisition, upgrades, plan changes, and billing questions
3. **Support Agent** - Provides technical support, troubleshooting, and account information lookups

### Tools

Each agent has access to specialized tools:

- **CRM Lookup** - Query customer account information by ID (Support Agent)
- **Create Lead** - Generate sales leads with customer information (Sales Agent)
- **Create Checkout** - Generate secure payment links for purchases (Sales Agent)
- **Search Docs** - Find troubleshooting steps in the knowledge base (Support Agent)
- **Escalate to Human** - Transfer complex issues to human agents (Support Agent)

## Workflow Examples

### Account Information + Technical Issue
```
User: "My account shows active but internet isn't working"
Triage Agent → Support Agent
Support Agent: 
  1. Asks for account ID and looks up account info
  2. Provides technical troubleshooting steps
  3. Handles complete conversation without handoffs
```

### Sales Inquiry
```
User: "I want to upgrade my plan"
Triage Agent → Sales Agent
Sales Agent: Creates lead and checkout link
```

### Technical Support Only
```
User: "My internet is slow"
Triage Agent → Support Agent  
Support Agent: Provides troubleshooting steps from docs
```

## Key Features

- **Intelligent Routing**: Triage agent analyzes customer requests and routes to appropriate specialists
- **Unified Support**: Support agent handles both technical issues and account lookups in one conversation
- **Task-Focused Design**: Each agent has clear, focused responsibilities to avoid handoff loops
- **Tool Integration**: Agents have access to all tools needed for their responsibilities
- **Conversation Continuity**: Full conversation history is maintained across agent handoffs
- **Flexible Architecture**: Easy to add new agents or modify routing logic

## Design Principles

This example demonstrates **task-focused agent design** to avoid handoff loops:

- **Support Agent** can handle both account lookups AND technical support
- **Sales Agent** focuses on sales, upgrades, and billing
- **Clear boundaries** prevent agents from bouncing requests back and forth
- **Comprehensive tooling** ensures agents can complete customer requests

## Data

The example includes sample data for:
- Customer accounts with service details  
- Knowledge base articles for troubleshooting
- Service plans and pricing information

## Usage

Run the interactive demo:

```bash
ruby examples/isp-support/interactive.rb
```

Try different types of requests:
- "I need info on my account" (account ID: CUST001, CUST002, or CUST003)
- "My account is active but internet isn't working" 
- "I want to upgrade my plan"
- "How much does fiber cost?"

The system will demonstrate intelligent routing and show how agents handle complex requests without unnecessary handoffs.

## File Structure

```
examples/isp-support/
├── README.md                    # This documentation
├── interactive.rb               # Interactive CLI demo
├── agents_factory.rb            # Agent creation and configuration
├── tools/
│   ├── crm_lookup_tool.rb      # Customer data retrieval
│   ├── create_lead_tool.rb     # Sales lead generation
│   ├── create_checkout_tool.rb # Payment link generation
│   ├── search_docs_tool.rb     # Knowledge base search
│   └── escalate_to_human_tool.rb # Human handoff
└── data/
    ├── customers.json          # Dummy customer database
    ├── plans.json             # Available service plans
    └── docs.json              # Troubleshooting knowledge base
```

## Learning Objectives

This example teaches you how to:

1. **Design Multi-Agent Systems**: Structure agents with clear responsibilities and communication patterns
2. **Avoid Handoff Loops**: Create task-focused agents that can handle complete customer requests
3. **Implement Context Sharing**: Pass information between agents while maintaining thread safety
4. **Create Domain-Specific Tools**: Build tools that integrate with external systems and business logic
5. **Handle Complex Workflows**: Route requests efficiently without unnecessary agent bouncing

This ISP support system demonstrates effective multi-agent architecture using the Ruby Agents SDK.