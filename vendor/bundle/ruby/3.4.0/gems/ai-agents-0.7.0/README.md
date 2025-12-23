<div align="center">
<br>
<br>
<p>
  <img src="./.github/ruby-agents.png" height="80px"/>
  <h1>
    AI Agents
  </h1>
</p>
<br>
<br>
</div>

A delightful provider agnostic Ruby SDK for building multi-agent AI workflows with seamless handoffs tool calling, and shared context.

## ✨ Features

- **🤖 Multi-Agent Orchestration**: Create specialized AI agents that work together
- **🔄 Seamless Handoffs**: Transparent agent-to-agent transfers (users never know!)
- **🛠️ Tool Integration**: Agents can use custom tools and functions
- **📊 Structured Output**: JSON schema-validated responses for reliable data extraction
- **💾 Shared Context**: State management across agent interactions
- **🔌 Provider Agnostic**: Works with OpenAI, Anthropic, and other LLM providers

## 🚀 Quick Start

### Installation

Add to your Gemfile:

```ruby
gem 'ai-agents'
```

### Basic Usage

```ruby
require 'agents'

# Configure with your API key
Agents.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
end

# Create agents
weather_agent = Agents::Agent.new(
  name: "Weather Assistant",
  instructions: "Help users get weather information",
  tools: [WeatherTool.new]
)

# Create a thread-safe runner (reusable across conversations)
runner = Agents::Runner.with_agents(weather_agent)

# Use the runner for conversations
result = runner.run("What's the weather like today?")
puts result.output
```

### Multi-Agent Workflows with Handoffs

The real power comes from multi-agent workflows with automatic handoffs:

```ruby
# Create specialized agents
triage = Agents::Agent.new(
  name: "Triage Agent",
  instructions: "Route customers to the right specialist"
)

sales = Agents::Agent.new(
  name: "Sales Agent",
  instructions: "Answer details about plans",
  tools: [CreateLeadTool.new, CRMLookupTool.new]
)

support = Agents::Agent.new(
  name: "Support Agent",
  instructions: "Handle account realted and technical issues",
  tools: [FaqLookupTool.new, TicketTool.new]
)

# Wire up handoff relationships - clean and simple!
triage.register_handoffs(sales, support)
sales.register_handoffs(triage)     # Can route back to triage
support.register_handoffs(triage)   # Hub-and-spoke pattern

# Create runner with all agents (triage is default entry point)
runner = Agents::Runner.with_agents(triage, sales, support)

# Run conversations with automatic handoffs and persistence
result = runner.run("Do you have special plans for businesses?")
# User gets direct answer from sales agent without knowing about the handoff!

# Continue the conversation seamlessly
result = runner.run("What is the pricing for the premium fibre plan?", context: result.context)
# Context automatically tracks conversation history and current agent
```

## 🏗️ Architecture

### Core Components

- **Agent**: Individual AI assistants configured with specific instructions, tools, and handoff relationships. Agents are immutable and thread-safe.
- **AgentRunner**: Thread-safe execution manager that coordinates multi-agent conversations. Create once and reuse across multiple threads safely.
- **Runner**: Internal orchestrator that handles individual conversation turns and manages the execution loop (used internally by AgentRunner).
- **Context & State**: Shared conversation state that persists across agent handoffs. Fully serializable for database storage and session management.
- **Tools**: Custom functions that agents can execute to interact with external systems (APIs, databases, etc.).
- **Handoffs**: Automatic transfers between specialized agents based on conversation context, completely transparent to users.

### Agent Definition

```ruby
# Create agents as instances
agent = Agents::Agent.new(
  name: "Customer Service",
  instructions: "You are a helpful customer service agent.",
  model: "gpt-4o",
  tools: [EmailTool.new, TicketTool.new]
)

# Register handoffs after creation
agent.register_handoffs(technical_support, billing)
```

### Custom Tools

```ruby
class EmailTool < Agents::Tool
  description "Send emails to customers"
  param :to, type: "string", desc: "Email address"
  param :subject, type: "string", desc: "Email subject"
  param :body, type: "string", desc: "Email body"

  def perform(tool_context, to:, subject:, body:)
    # Send email logic here
    "Email sent to #{to}"
  end
end
```

### Handoff Patterns

```ruby
# Central triage agent routes to specialists (hub-and-spoke pattern)
triage = Agents::Agent.new(name: "Triage")
billing = Agents::Agent.new(name: "Billing")
support = Agents::Agent.new(name: "Support")

# Triage can route to any specialist
triage.register_handoffs(billing, support)

# Specialists only route back to triage
billing.register_handoffs(triage)
support.register_handoffs(triage)
```

### Context Management & Persistence

```ruby
# Context is automatically managed and serializable
runner = Agents::Runner.with_agents(triage, billing, support)

# Start a conversation
result = runner.run("I need billing help")

# Context is automatically updated with conversation history and current agent
context = result.context
puts context[:conversation_history]
puts context[:current_agent]  # Agent name (string), not object!

# Serialize context for persistence (Rails, databases, etc.)
json_context = JSON.dump(context)

# Later: restore and continue conversation
restored_context = JSON.parse(json_context, symbolize_names: true)
result = runner.run("Actually, I need technical support too", context: restored_context)
# System automatically determines correct agent from conversation history
```

## 📋 Examples

Check out the `examples/` folder for complete working demos showcasing multi-agent workflows.

```bash
# Run the ISP support demo
ruby examples/isp-support/interactive.rb
```

## 🔧 Configuration

```ruby
Agents.configure do |config|
  # Provider API keys
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']

  # Defaults
  config.default_provider = :openai
  config.default_model = 'gpt-4o'

  # Performance
  config.request_timeout = 120
  config.max_turns = 10

  # Debugging
  config.debug = true
end
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`rake test`)
4. Run linter (`rake rubocop`)
5. Commit your changes (`git commit -am 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by [OpenAI's Agents SDK](https://github.com/openai/agents)
- Built on top of [RubyLLM](https://rubyllm.com) for LLM integration
