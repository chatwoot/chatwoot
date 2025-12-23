# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This project is a Ruby SDK for building multi-agent AI workflows. It allows developers to create specialized AI agents that can collaborate to solve complex tasks. The key features include:

-   **Multi-Agent Orchestration**: Defining and managing multiple AI agents with distinct roles.
-   **Seamless Handoffs**: Transferring conversations between agents without the user's knowledge.
-   **Tool Integration**: Allowing agents to use custom tools to interact with external systems.
-   **Real-time Callbacks**: Event-driven system for monitoring agent execution, tool usage, and handoffs.
-   **Shared Context**: Maintaining state and conversation history across agent interactions with full persistence support.
-   **Thread-Safe Architecture**: Reusable agent runners that work safely across multiple threads.
-   **Provider Agnostic**: Supporting various LLM providers like OpenAI, Anthropic, and Gemini.

## Key Technologies

-   **Ruby**: The primary programming language.
-   **RubyLLM**: The underlying library for interacting with Large Language Models.
-   **RSpec**: The testing framework.
-   **RuboCop**: The code style linter.
-   **GitHub Actions**: For continuous integration (testing and linting).

## Project Structure

-   `lib/`: The core source code of the `ai-agents` gem.
    -   `lib/agents.rb`: The main entry point, handling configuration and loading other components.
    -   `lib/agents/agent.rb`: Defines the `Agent` class, which represents an individual AI agent.
    -   `lib/agents/tool.rb`: Defines the `Tool` class, the base for creating custom tools for agents.
    -   `lib/agents/agent_runner.rb`: Thread-safe agent execution manager for multi-agent conversations.
    -   `lib/agents/runner.rb`: Internal orchestrator that handles individual conversation turns.
-   `spec/`: Contains the RSpec tests for the project.
-   `examples/`: Includes example implementations of multi-agent systems, such as an ISP customer support demo.
-   `Gemfile`: Manages the project's Ruby dependencies.
-   `.rubocop.yml`: Configures the code style rules for RuboCop.
-   `.github/workflows/main.yml`: Defines the CI pipeline for running tests and linting on push and pull requests.

## Development Workflow

1.  **Dependencies**: Managed by Bundler (`bundle install`).
2.  **Testing**: Run tests with `bundle exec rspec`.
3.  **Linting**: Check code style with `bundle exec rubocop`.
4.  **CI/CD**: GitHub Actions automatically runs tests and linting for all pushes and pull requests to the `main` branch.

## How to Run the Example

The project includes an interactive example of an ISP customer support system. To run it:

```bash
ruby examples/isp-support/interactive.rb
```

This will start a command-line interface where you can interact with the multi-agent system. The example demonstrates:
- Thread-safe agent runner creation
- Real-time callback system with UI feedback
- Automatic agent selection based on conversation history
- Context persistence that works across process boundaries
- Seamless handoffs between triage, sales, and support agents

## Key Concepts

-   **Agent**: An AI assistant with a specific role, instructions, and tools.
-   **Tool**: A custom function that an agent can use to perform actions (e.g., look up customer data, send an email).
-   **Handoff**: The process of transferring a conversation from one agent to another. This is a core feature of the SDK.
-   **Runner**: Internal component that manages individual conversation turns (used by AgentRunner).
-   **Context**: A shared state object that stores conversation history and agent information, fully serializable for persistence.
-   **Callbacks**: Event hooks for monitoring agent execution, including agent thinking, tool start/complete, and handoffs.

## Development Commands

### Testing
```bash
# Run all tests with RSpec
bundle exec rspec

# Run tests with coverage report (uses SimpleCov)
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/agents/agent_spec.rb

# Run specific test with line number
bundle exec rspec spec/agents/agent_spec.rb:25
```

### Code Quality
```bash
# Run RuboCop linter
bundle exec rubocop

# Run RuboCop with auto-correction
bundle exec rubocop -a

# Run both tests and linting (default rake task)
bundle exec rake
```

### Development
```bash
# Install dependencies
bundle install

# Interactive Ruby console with gem loaded
bundle exec irb -r ./lib/agents

# Run ISP support example interactively
ruby examples/isp-support/interactive.rb
```

## Architecture

### Core Components

- **Agents::Agent**: Individual AI agents with specific roles, instructions, and tools
- **Agents::Runner**: Orchestrates multi-agent conversations with automatic handoffs
- **Agents::Tool**: Base class for custom tools that agents can execute
- **Agents::Context**: Shared state management across agent interactions
- **Agents::Handoff**: Manages seamless transfers between agents
- **Agents::CallbackManager**: Centralized event handling for real-time monitoring

### Key Design Principles

1. **Thread Safety**: All components are designed to be thread-safe. Tools receive context as parameters, not instance variables.

2. **Immutable Agents**: Agents are configured once and can be cloned with modifications. No execution state is stored in agent instances.

3. **Provider Agnostic**: Built on RubyLLM, supports OpenAI, Anthropic, and Gemini through configuration.


### File Structure

```
lib/agents/
├── agent.rb            # Core agent definition and configuration
├── agent_runner.rb     # Thread-safe execution manager (main API)
├── runner.rb           # Internal execution engine for conversation turns
├── tool.rb             # Base class for custom tools
├── handoff.rb          # Agent handoff management
├── chat.rb             # Chat message handling
├── result.rb           # Result object for agent responses
├── run_context.rb      # Execution context management
├── tool_context.rb     # Tool execution context
├── tool_wrapper.rb     # Thread-safe tool wrapping
├── callback_manager.rb # Centralized callback event handling
├── message_extractor.rb # Conversation history processing
└── version.rb          # Gem version
```

### Configuration

The SDK requires at least one LLM provider API key:

```ruby
Agents.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
  config.default_model = 'gpt-4o-mini'
  config.debug = true
end
```

### Basic Usage Pattern

```ruby
# Create agents with handoff relationships
triage = Agent.new(name: "Triage", instructions: "Route users...")
billing = Agent.new(name: "Billing", instructions: "Handle billing...")
support = Agent.new(name: "Support", instructions: "Technical support...")

triage.register_handoffs(billing, support)

# Create thread-safe runner (first agent is default entry point)
runner = Agents::Runner.with_agents(triage, billing, support)

# Add real-time callbacks for monitoring
runner.on_agent_thinking { |agent_name, input| puts "🧠 #{agent_name} is thinking..." }
runner.on_tool_start { |tool_name, args| puts "🔧 Using #{tool_name}..." }
runner.on_tool_complete { |tool_name, result| puts "✅ #{tool_name} completed" }
runner.on_agent_handoff { |from, to, reason| puts "🔄 Handoff: #{from} → #{to}" }

# Use for conversations - automatically handles agent selection and persistence
result = runner.run("I have a billing question")
result = runner.run("What about technical support?", context: result.context)
```

### Tool Development

When creating custom tools:
- Extend `Agents::Tool`
- Use `tool_context` parameter for all state
- Never store execution state in instance variables
- Follow the thread-safe design pattern shown in examples

### Testing Strategy

The codebase follows comprehensive testing patterns with strong emphasis on thread safety and isolation, here's some points to note

- SimpleCov tracks coverage with 50% minimum overall, 40% per file
- RSpec testing framework with descriptive context blocks
- Tests organized by component in `spec/agents/` mirroring lib structure
- **Instance Doubles**: Extensive use of `instance_double` for clean dependency mocking, never use generic `double` or `stub`
- **WebMock**: HTTP call stubbing with network isolation (`WebMock.disable_net_connect!`)
- Unit tests for individual components
- Integration tests for complex workflows
- Thread-safety tests for concurrent scenarios
- Clear separation of setup, execution, and assertion phases
- Context description should always match /^when\b/, /^with\b/, or /^without\b/.

### Examples

The `examples/` directory contains complete working examples:
- `isp-support/`: Multi-agent ISP customer support system
- Shows hub-and-spoke architecture patterns
- Demonstrates tool integration and handoff workflows
- Includes real-time callback implementation for UI feedback

## Callback System

The SDK includes a comprehensive callback system for monitoring agent execution in real-time. This is particularly useful for:

- **UI Feedback**: Show users what's happening during agent execution
- **Debugging**: Track tool usage and agent handoffs
- **Analytics**: Monitor system performance and usage patterns
- **Rails Integration**: Stream updates via ActionCable

### Available Callbacks

- `on_agent_thinking`: Triggered when an agent starts processing
- `on_tool_start`: Triggered when a tool begins execution
- `on_tool_complete`: Triggered when a tool finishes execution
- `on_agent_handoff`: Triggered when control transfers between agents

### Callback Integration

Callbacks are thread-safe and non-blocking. If a callback raises an exception, it won't interrupt agent execution. The system uses a centralized CallbackManager for efficient event handling.

For detailed callback documentation, see `docs/concepts/callbacks.md`.
