## How to write tests

Before you start writing any new tests, run the entire test suite to ensure everything is working as expected. Fix any issues that arise. Here's some things to keep in mind:

1. Always fix the tests one by one
2. Ensure each test passes before moving on to the next.
3. Once done, run rubocop -A for the test file, but ignore errors
4. Commit the existing fixes with a appropriate semantic commit message

Once done, we can start testing the new stuff. Here's a pattern you need to follow:

1. Create the skeleton of the test
2. Write an example, run it to ensure it passes
3. Run rubocop -A for the test file, but ignore errors
4. Once all the tests are complete for a file

**NEVER ADD CO-AUTHOR TO THE COMMIT**


# Chatwoot Captain Agent System - AIAgents Ruby Gem Integration

## AI Agents Documentation Index

### Core Concepts
- **[Agents](https://ruby-ai-agents.netlify.app/concepts/agents.html)** - Core agent concepts and creation
- **[Tools](https://ruby-ai-agents.netlify.app/concepts/tools.html)** - Tool implementation and usage
- **[Agent-Tool Pattern](https://ruby-ai-agents.netlify.app/concepts/agent-tool.html)** - How agents interact with tools
- **[Context](https://ruby-ai-agents.netlify.app/concepts/context.html)** - Managing shared context between agents
- **[Handoffs](https://ruby-ai-agents.netlify.app/concepts/handoffs.html)** - Agent-to-agent handoff mechanisms
- **[Runner](https://ruby-ai-agents.netlify.app/concepts/runner.html)** - AgentRunner for orchestration
- **[Callbacks](https://ruby-ai-agents.netlify.app/concepts/callbacks.html)** - Event callbacks and hooks

### Integration Guides
- **[Rails Integration](https://ruby-ai-agents.netlify.app/guides/rails-integration.html)** - Integrating with Rails applications
- **[Multi-Agent Systems](https://ruby-ai-agents.netlify.app/guides/multi-agent-systems.html)** - Building complex agent systems
- **[Agent as Tool Pattern](https://ruby-ai-agents.netlify.app/guides/agent-as-tool-pattern.html)** - Using agents as tools
- **[State Persistence](https://ruby-ai-agents.netlify.app/guides/state-persistence.html)** - Persisting agent state

### General
- **[Homepage](https://ruby-ai-agents.netlify.app/)** - Overview and getting started
- **[Concepts](https://ruby-ai-agents.netlify.app/concepts.html)** - All concepts overview
- **[Guides](https://ruby-ai-agents.netlify.app/guides.html)** - All guides overview

## Overview

The Chatwoot Captain agent system is built using the `ai-agents` gem (version >= 0.2.1) to provide AI-powered automation capabilities. The system follows a modular architecture with scenarios, assistants, and tools.

## Core Components

### 1. Captain::Scenario (`enterprise/app/models/captain/scenario.rb`)
- Main entity that defines agent behaviors and configurations
- Belongs to a `Captain::Assistant` and `Account`
- Key attributes:
  - `title`: Scenario name
  - `description`: What the scenario does
  - `instruction`: Instructions for the agent with tool references
  - `tools`: JSONB array of tool IDs
  - `enabled`: Boolean flag

#### Agent Creation
```ruby
def agent(user)
  tool_instances = agent_tools.map { |tool| tool.new(assistant, user: user) }
  Agents::Agent.new(
    name: "#{title} Agent".titleize,
    instructions: agent_instructions,
    tools: tool_instances
  )
end
```

### 2. Captain::Assistant (`enterprise/app/models/captain/assistant.rb`)
- Represents an AI assistant that can have multiple scenarios
- Has many:
  - `scenarios`: Different agent behaviors
  - `documents`: Knowledge base documents
  - `captain_inboxes`: Connected inboxes
  - `copilot_threads`: Conversation threads
  - `responses`: Historical responses

### 3. Tool System

#### Base Tool Class (`enterprise/lib/captain/tools/base_agent_tool.rb`)
```ruby
class Captain::Tools::BaseAgentTool < Agents::Tool
  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
    @account_user = find_account_user if @user.present?
    super()
  end
```

- Extends `Agents::Tool` from the ai-agents gem
- Provides permission checking via `active?` method
- Helper methods for account-scoped queries and logging

#### Available Tools
From `config/agents/tools.yml`:
1. **add_contact_note**: Add notes to contact profiles
2. **add_private_note**: Add internal notes to conversations
3. **update_priority**: Change conversation priority levels
4. **search_contact**: Search contacts by email/phone/identifier
5. **add_label_to_conversation**: Tag conversations with labels

#### Tool Implementation Pattern
All tools now follow a consistent pattern using the ai-agents DSL:

```ruby
class Captain::Tools::AddContactNoteTool < Captain::Tools::BaseAgentTool
  description 'Add a note to a contact profile'
  param :contact_id, type: 'string', desc: 'The ID of the contact'
  param :note, type: 'string', desc: 'The note content to add to the contact'

  def perform(_tool_context, note:, contact_id:)
    # Implementation
  end
end
```

**Key aspects of the pattern:**
- Use `description` class method to describe the tool's purpose
- Use `param` class method to define parameters with type and description
- Implement `perform` method that receives tool context and named parameters
- Return structured responses (success/error) for consistent handling

### 4. Tool Resolution System (`CaptainToolsHelpers`)
- Provides methods to load and resolve tools
- Tool references in instructions use format: `(tool://tool_id)`
- Automatically extracts and validates tool references from scenario instructions

## Integration with AIAgents Gem

### Configuration
The ai-agents gem is configured with API keys (likely in an initializer):
```ruby
Agents.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  # Other provider keys
end
```

### Agent Creation Flow
1. User creates a `Captain::Scenario` with instructions and tool references
2. Scenario validates tool references against available tools
3. When needed, scenario creates an `Agents::Agent` instance with:
   - Name derived from scenario title
   - Instructions including resolved tool descriptions
   - Tool instances initialized with assistant and user context

### Tool Execution
- Tools inherit from `Agents::Tool` base class
- Each tool has access to:
  - `@assistant`: The Captain assistant instance
  - `@user`: Current user executing the tool
  - `@account_user`: Account-specific user permissions
- Tools check permissions before execution
- All actions are logged for audit trails

## Security & Permissions
- Tools implement `active?` method to check user permissions
- Permissions checked include:
  - `contact_manage`: For contact-related operations
  - `conversation_manage`: For conversation updates
  - `conversation_unassigned_manage`: For unassigned conversations
  - `conversation_participating_manage`: For participated conversations
- Account-scoped queries prevent cross-account data access

## Current State
All tools have been updated to use the ai-agents gem's DSL for consistent parameter definitions. The integration provides a flexible framework for adding new AI-powered automation capabilities to Chatwoot.

## Assistant and Scenario Agent Architecture

### Assistant as Main Agent
The `Captain::Assistant` model now has an `agent` method that creates the main assistant agent with scenario handoffs:

```ruby
def agent(user)
  # Get enabled scenario agents as handoff agents
  handoff_agents = scenarios.enabled.map { |scenario| scenario.agent(user) }

  # Create the main assistant agent with scenario agents as handoffs
  Agents::Agent.new(
    name: name,
    instructions: agent_instructions,
    handoff_agents: handoff_agents
  )
end
```

### Handoff Pattern
- Assistant agent analyzes user requests and determines if they match specific scenarios
- When a match is found, the assistant hands off to the appropriate scenario agent
- Scenario agents have specialized instructions and tools for their specific tasks

## Conversation Context Management

### Current Implementation
The existing system maintains conversation context through:

1. **Message History Collection** (`Captain::Conversation::ResponseBuilderJob`):
```ruby
def collect_previous_messages
  @conversation
    .messages
    .where(message_type: [:incoming, :outgoing])
    .where(private: false)
    .map do |message|
    {
      content: prepare_multimodal_message_content(message),
      role: determine_role(message)
    }
  end
end
```

2. **Message Content Building** (`Captain::OpenAiMessageBuilderService`):
- Handles text content
- Processes image attachments
- Includes audio transcriptions
- Supports multimodal messages

3. **Direct OpenAI Integration**:
- Uses `Captain::Llm::AssistantChatService` for chat completions
- Maintains message history as an array of role/content pairs
- Not yet using the ai-agents gem's context management

### AI-Agents Context Management
The ai-agents gem provides sophisticated context management:

1. **Context Structure**:
- Serializable state management system
- Preserves information across agent interactions
- Can be stored and restored between sessions

2. **Usage with AgentRunner**:
```ruby
runner = Agents::AgentRunner.new(agent: assistant_agent)
result = runner.run(message, context: previous_context)
new_context = result.context
```

3. **Integration Opportunity**:
- Convert conversation messages to ai-agents context format
- Persist context between conversation turns
- Enable seamless handoffs with shared context

## Current Captain Assistant Flow

### 1. Message Creation Trigger
When a new message is created in a conversation:
- `Message#execute_after_create_commit_callbacks` is called
- This invokes `execute_message_template_hooks`
- Which calls `MessageTemplates::HookExecutionService.new(message: self).perform`

### 2. Hook Execution Service (Enterprise Module)
The enterprise module `Enterprise::MessageTemplates::HookExecutionService` is prepended to the base service:
- Checks `should_process_captain_response?`:
  - Conversation must be pending
  - Message must be incoming
  - Inbox must have a captain_assistant assigned
- Checks if `inbox.captain_active?`:
  - Captain assistant must be present
  - Account must have available captain responses (usage limits)
- If active, schedules `Captain::Conversation::ResponseBuilderJob`
- If not active (limit exceeded), performs handoff

### 3. Response Builder Job
`Captain::Conversation::ResponseBuilderJob` processes the assistant response:
1. **Collects message history**:
   - Fetches all non-private incoming/outgoing messages from conversation
   - Uses `Captain::OpenAiMessageBuilderService` to format messages (handles text, images, audio transcriptions)
   - Maps messages to role/content format for OpenAI

2. **Generates response**:
   - Uses `Captain::Llm::AssistantChatService` with the assistant
   - Passes message_history to `generate_response`
   - This service uses direct OpenAI API calls (not ai-agents gem)

3. **Processes response**:
   - If response is 'conversation_handoff', triggers handoff
   - Otherwise, creates outgoing message with assistant as sender
   - Increments account's response usage counter

### 4. Key Models and Associations
- **Inbox** has_one **CaptainInbox** has_one **Captain::Assistant**
- **Captain::Assistant** has_many **scenarios** (but not used in current flow)
- **Message** belongs_to **sender** (polymorphic - can be Captain::Assistant)

### 5. Limitations of Current Implementation
- Uses direct OpenAI API integration, not ai-agents gem
- No scenario execution or handoffs to specialized agents
- No persistent context management between conversations
- Tool execution happens through a separate registry system, not ai-agents tools

## Notes
- The `Captain::Agent` class in `enterprise/lib/captain/agent.rb` appears to be a legacy implementation
- Current assistant implementation uses direct OpenAI API calls via `AssistantChatService`
- Scenario agents are defined but not yet integrated into the conversation flow
- To fully leverage the ai-agents gem, a new service using `AgentRunner` needs to be created that:
  - Uses the assistant's `agent(user)` method
  - Manages context across conversation turns
  - Enables handoffs to scenario agents
  - Integrates with the existing conversation flow
