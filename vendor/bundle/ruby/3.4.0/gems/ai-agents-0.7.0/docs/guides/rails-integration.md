---
layout: default
title: Rails Integration
parent: Guides
nav_order: 2
---

# Rails Integration

This guide covers integrating the AI Agents library with Ruby on Rails applications, including conversation persistence with ActiveRecord and session management.

## Setup

Add the gem to your Rails application:

```ruby
# Gemfile
gem 'ai-agents'
```

Configure your LLM providers in an initializer:

```ruby
# config/initializers/ai_agents.rb
Agents.configure do |config|
  config.openai_api_key = Rails.application.credentials.openai_api_key
  config.anthropic_api_key = Rails.application.credentials.anthropic_api_key
  config.default_model = 'gpt-4o-mini'
  config.debug = Rails.env.development?
end
```

## ActiveRecord Integration

### Conversation Persistence

Create a model to store conversation contexts:

```ruby
# Generate migration
rails generate model Conversation user:references context:text current_agent:string

# db/migrate/xxx_create_conversations.rb
class CreateConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.text :context, null: false
      t.string :current_agent
      t.timestamps
    end

    add_index :conversations, [:user_id, :created_at]
  end
end
```

Define the Conversation model:

```ruby
# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :user

  # Serialize context as JSON
  serialize :context, JSON

  validates :context, presence: true

  def self.for_user(user)
    where(user: user).order(:created_at)
  end

  def self.latest_for_user(user)
    for_user(user).last
  end

  # Convert to agent context hash
  def to_agent_context
    context.deep_symbolize_keys
  end

  # Create from agent result
  def self.from_agent_result(user, result)
    create!(
      user: user,
      context: result.context.to_h,
      current_agent: result.context[:current_agent]
    )
  end
end
```

### Session Management

Create a service to manage agent conversations:

```ruby
# app/services/agent_conversation_service.rb
class AgentConversationService
  def initialize(user)
    @user = user
    @runner = create_agent_runner
  end

  def send_message(message)
    # Get existing conversation context
    context = load_conversation_context

    # Run agent with message
    result = @runner.run(message, context: context)

    # Persist updated conversation
    save_conversation(result)

    result
  end

  def reset_conversation
    Conversation.where(user: @user).destroy_all
  end

  private

  def create_agent_runner
    # Create your agents here
    triage_agent = Agents::Agent.new(
      name: "Triage",
      instructions: build_triage_instructions,
      tools: [CustomerLookupTool.new]
    )

    billing_agent = Agents::Agent.new(
      name: "Billing",
      instructions: "Handle billing and payment inquiries.",
      tools: [BillingTool.new, PaymentTool.new]
    )

    support_agent = Agents::Agent.new(
      name: "Support",
      instructions: "Provide technical support and troubleshooting.",
      tools: [TechnicalTool.new]
    )

    triage_agent.register_handoffs(billing_agent, support_agent)

    Agents::Runner.with_agents(triage_agent, billing_agent, support_agent)
  end

  def build_triage_instructions
    ->(context) {
      user_info = context[:user_info] || {}

      <<~INSTRUCTIONS
        You are a customer service triage agent for #{@user.name}.

        Customer Details:
        - Name: #{@user.name}
        - Email: #{@user.email}
        - Account Type: #{user_info[:account_type] || 'standard'}

        Route customers to the appropriate department:
        - Billing: Payment issues, account billing, refunds
        - Support: Technical problems, product questions

        Always be professional and helpful.
      INSTRUCTIONS
    }
  end

  def load_conversation_context
    latest_conversation = Conversation.latest_for_user(@user)
    return initial_context unless latest_conversation

    latest_conversation.to_agent_context
  end

  def initial_context
    {
      user_id: @user.id,
      user_info: {
        name: @user.name,
        email: @user.email,
        account_type: @user.account_type
      }
    }
  end

  def save_conversation(result)
    Conversation.from_agent_result(@user, result)
  end
end
```

## Controller Integration

Create a controller for handling agent conversations:

```ruby
# app/controllers/agent_conversations_controller.rb
class AgentConversationsController < ApplicationController
  before_action :authenticate_user!

  def create
    service = AgentConversationService.new(current_user)

    begin
      result = service.send_message(params[:message])

      render json: {
        response: result.output,
        agent: result.context[:current_agent],
        conversation_id: result.context[:conversation_id]
      }
    rescue => e
      Rails.logger.error "Agent conversation error: #{e.message}"
      render json: { error: "Unable to process your request" }, status: 500
    end
  end

  def reset
    service = AgentConversationService.new(current_user)
    service.reset_conversation

    render json: { message: "Conversation reset successfully" }
  end

  def history
    conversations = Conversation.for_user(current_user)
                               .includes(:user)
                               .limit(50)

    render json: conversations.map do |conv|
      {
        id: conv.id,
        agent: conv.current_agent,
        timestamp: conv.created_at,
        context_keys: conv.context.keys
      }
    end
  end
end
```

## Custom Rails Tools

Create Rails-specific tools for database operations:

```ruby
# app/tools/customer_lookup_tool.rb
class CustomerLookupTool < Agents::Tool
  name "lookup_customer"
  description "Look up customer information by email or ID"
  param :identifier, type: "string", desc: "Email address or customer ID"

  def perform(tool_context, identifier:)
    # Access Rails models safely
    customer = User.find_by(email: identifier) || User.find_by(id: identifier)

    return "Customer not found" unless customer

    {
      name: customer.name,
      email: customer.email,
      account_type: customer.account_type,
      created_at: customer.created_at,
      last_login: customer.last_sign_in_at
    }
  end
end

# app/tools/billing_tool.rb
class BillingTool < Agents::Tool
  name "get_billing_info"
  description "Retrieve billing information for a customer"
  param :user_id, type: "integer", desc: "Customer user ID"

  def perform(tool_context, user_id:)
    user = User.find(user_id)
    billing_info = user.billing_profile

    return "No billing information found" unless billing_info

    {
      plan: billing_info.plan_name,
      status: billing_info.status,
      next_billing_date: billing_info.next_billing_date,
      amount: billing_info.monthly_amount
    }
  rescue ActiveRecord::RecordNotFound
    "Customer not found"
  end
end
```

## Background Processing

For longer conversations, use background jobs:

```ruby
# app/jobs/agent_conversation_job.rb
class AgentConversationJob < ApplicationJob
  queue_as :default

  def perform(user_id, message, conversation_id = nil)
    user = User.find(user_id)
    service = AgentConversationService.new(user)

    result = service.send_message(message)

    # Broadcast result via ActionCable
    ActionCable.server.broadcast(
      "agent_conversation_#{user_id}",
      {
        response: result.output,
        agent: result.context[:current_agent],
        conversation_id: conversation_id
      }
    )
  end
end

# Enqueue job from controller
def create_async
  job_id = AgentConversationJob.perform_later(
    current_user.id,
    params[:message],
    params[:conversation_id]
  )

  render json: { job_id: job_id }
end
```

## Error Handling

Implement comprehensive error handling:

```ruby
# app/services/agent_conversation_service.rb
class AgentConversationService
  class AgentError < StandardError; end
  class ContextError < StandardError; end

  def send_message(message)
    validate_message(message)

    context = load_conversation_context

    begin
      result = @runner.run(message, context: context)
      save_conversation(result)
      result
    rescue RubyLLM::Error => e
      Rails.logger.error "LLM Error: #{e.message}"
      raise AgentError, "AI service temporarily unavailable"
    rescue JSON::ParserError => e
      Rails.logger.error "Context parsing error: #{e.message}"
      raise ContextError, "Conversation context corrupted"
    end
  end

  private

  def validate_message(message)
    raise ArgumentError, "Message cannot be blank" if message.blank?
    raise ArgumentError, "Message too long" if message.length > 5000
  end
end
```

## Testing

Test Rails integration with RSpec:

```ruby
# spec/services/agent_conversation_service_spec.rb
RSpec.describe AgentConversationService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#send_message' do
    it 'creates a conversation record' do
      expect {
        service.send_message("Hello")
      }.to change(Conversation, :count).by(1)
    end

    it 'persists context correctly' do
      result = service.send_message("Hello")
      conversation = Conversation.last

      expect(conversation.user).to eq(user)
      expect(conversation.context).to include('user_id' => user.id)
    end
  end

  describe '#reset_conversation' do
    before { service.send_message("Hello") }

    it 'destroys all conversations for user' do
      expect {
        service.reset_conversation
      }.to change(Conversation, :count).by(-1)
    end
  end
end
```

## Deployment Considerations

### Environment Variables

```ruby
# config/credentials.yml.enc
openai_api_key: your_openai_key
anthropic_api_key: your_anthropic_key

# Or use environment variables
ENV['OPENAI_API_KEY']
ENV['ANTHROPIC_API_KEY']
```

### Database Indexing

```ruby
# Add indexes for better query performance
add_index :conversations, [:user_id, :current_agent]
add_index :conversations, :created_at
```

### Memory Management

```ruby
# Cleanup old conversations
# config/schedule.rb (whenever gem)
every 1.day, at: '2:00 am' do
  runner "Conversation.where('created_at < ?', 30.days.ago).destroy_all"
end
```
