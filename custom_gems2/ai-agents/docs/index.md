---
layout: default
title: Home
nav_order: 1
description: "AI Agents is a Ruby SDK for building multi-agent AI workflows."
permalink: /
---

# AI Agents

A Ruby SDK for building sophisticated multi-agent AI workflows.

{: .fs-6 .fw-300 }

[Get started now](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View it on GitHub](https://github.com/chatwoot/ai-agents){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## What is AI Agents?

AI Agents is a Ruby SDK that enables developers to create sophisticated multi-agent AI workflows. Build specialized AI agents that can collaborate, use tools, and seamlessly hand off conversations to solve complex tasks.

### Key Features

- **Multi-Agent Orchestration**: Define and manage multiple AI agents with distinct roles
- **Seamless Handoffs**: Transfer conversations between agents without user knowledge
- **Tool Integration**: Allow agents to use custom tools to interact with external systems
- **Callbacks**: Real-time notifications for agent thinking, tool execution, and handoffs
- **Shared Context**: Maintain state and conversation history across agent interactions
- **Thread-Safe Architecture**: Reusable agent runners that work safely across multiple threads
- **Provider Agnostic**: Support for OpenAI, Anthropic, and Gemini

## Getting Started

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'ai-agents'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ai-agents
```

### Quick Start

```ruby
require 'agents'

# Configure your API keys
Agents.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  # config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  # config.gemini_api_key = ENV['GEMINI_API_KEY']
  config.default_model = 'gpt-4o-mini'
end

# Create agents
triage = Agents::Agent.new(
  name: "Triage",
  instructions: "You help route customer inquiries to the right department."
)

support = Agents::Agent.new(
  name: "Support", 
  instructions: "You provide technical support for our products."
)

# Set up handoffs
triage.register_handoffs(support)

# Create runner and start conversation
runner = Agents::Runner.with_agents(triage, support)
result = runner.run("I need help with a technical issue")

puts result.output
```

## Next Steps

- [Learn about Agents](concepts/agents.html)
- [Understand Context](concepts/context.html)
- [Working with Tools](concepts/tools.html)
- [Agent Handoffs](concepts/handoffs.html)
- [Using the Runner](concepts/runner.html)
- [Callbacks](concepts/callbacks.html)
