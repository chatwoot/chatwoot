---
name: automation-rules
description: Create and manage automation rules in Chatwoot for auto-assigning conversations, sending messages, and triggering actions based on events. Use this skill when implementing workflow automation features.
metadata:
  author: chatwoot
  version: "1.0"
---

# Automation Rules

## Overview

Chatwoot automation rules allow automatic actions based on conversation events. Rules consist of conditions and actions that execute when conditions match.

## Database Model

```ruby
# app/models/automation_rule.rb
class AutomationRule < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :event_name, presence: true
  validates :conditions, presence: true
  validates :actions, presence: true

  # Event types
  EVENTS = %w[
    conversation_created
    conversation_updated
    message_created
    conversation_opened
  ].freeze

  # Condition attributes
  CONDITION_ATTRIBUTES = %w[
    status
    assignee_id
    team_id
    inbox_id
    labels
    browser_language
    country_code
    message_type
    content
  ].freeze

  scope :active, -> { where(active: true) }
end
```

## Rule Structure

### JSON Schema

```json
{
  "name": "Auto-assign VIP customers",
  "description": "Assign conversations from VIP customers to senior team",
  "event_name": "conversation_created",
  "conditions": [
    {
      "attribute_key": "contact.custom_attributes.customer_type",
      "filter_operator": "equal_to",
      "values": ["vip"]
    },
    {
      "attribute_key": "inbox_id",
      "filter_operator": "equal_to",
      "values": [1, 2, 3]
    }
  ],
  "actions": [
    {
      "action_name": "assign_team",
      "action_params": [5]
    },
    {
      "action_name": "add_label",
      "action_params": ["priority", "vip"]
    }
  ]
}
```

## Conditions

### Filter Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `equal_to` | Exact match | status == "open" |
| `not_equal_to` | Not equal | status != "resolved" |
| `contains` | String contains | content contains "urgent" |
| `does_not_contain` | String doesn't contain | content not contains "spam" |
| `is_present` | Value exists | assignee_id is present |
| `is_not_present` | Value is null | team_id is not present |
| `starts_with` | String starts with | email starts with "support" |

### Condition Attributes

```ruby
# Conversation attributes
- status
- assignee_id
- team_id
- inbox_id
- priority
- labels

# Contact attributes
- contact.email
- contact.phone_number
- contact.country_code
- contact.custom_attributes.*

# Message attributes (for message events)
- message_type
- content
- sender_type
```

## Actions

### Available Actions

```ruby
ACTION_TYPES = {
  assign_agent: 'Assign to specific agent',
  assign_team: 'Assign to team',
  add_label: 'Add labels to conversation',
  remove_label: 'Remove labels from conversation',
  send_message: 'Send automated message',
  send_email: 'Send email notification',
  mute_conversation: 'Mute conversation',
  resolve_conversation: 'Auto-resolve conversation',
  send_webhook: 'Trigger external webhook'
}.freeze
```

## Implementing Automation Processor

### Rule Engine

```ruby
# app/services/automation_rules/conditions_filter_service.rb
class AutomationRules::ConditionsFilterService
  def initialize(rule, conversation, message: nil)
    @rule = rule
    @conversation = conversation
    @message = message
  end

  def perform
    @rule.conditions.all? do |condition|
      evaluate_condition(condition)
    end
  end

  private

  def evaluate_condition(condition)
    attribute_value = fetch_attribute_value(condition['attribute_key'])
    filter_value = condition['values']
    operator = condition['filter_operator']

    case operator
    when 'equal_to'
      filter_value.include?(attribute_value)
    when 'not_equal_to'
      !filter_value.include?(attribute_value)
    when 'contains'
      filter_value.any? { |v| attribute_value.to_s.include?(v.to_s) }
    when 'is_present'
      attribute_value.present?
    when 'is_not_present'
      attribute_value.blank?
    else
      false
    end
  end

  def fetch_attribute_value(key)
    parts = key.split('.')
    
    case parts.first
    when 'contact'
      fetch_contact_attribute(parts[1..])
    when 'message'
      fetch_message_attribute(parts[1..])
    else
      @conversation.public_send(key)
    end
  end

  def fetch_contact_attribute(parts)
    contact = @conversation.contact
    return nil unless contact

    if parts.first == 'custom_attributes'
      contact.custom_attributes&.dig(*parts[1..])
    else
      contact.public_send(parts.first)
    end
  end
end
```

### Action Executor

```ruby
# app/services/automation_rules/action_service.rb
class AutomationRules::ActionService
  def initialize(rule, conversation)
    @rule = rule
    @conversation = conversation
    @account = conversation.account
  end

  def perform
    @rule.actions.each do |action|
      execute_action(action)
    end
  end

  private

  def execute_action(action)
    case action['action_name']
    when 'assign_agent'
      assign_agent(action['action_params'].first)
    when 'assign_team'
      assign_team(action['action_params'].first)
    when 'add_label'
      add_labels(action['action_params'])
    when 'remove_label'
      remove_labels(action['action_params'])
    when 'send_message'
      send_message(action['action_params'].first)
    when 'resolve_conversation'
      resolve_conversation
    when 'send_webhook'
      send_webhook(action['action_params'].first)
    end
  end

  def assign_agent(agent_id)
    agent = @account.users.find_by(id: agent_id)
    return unless agent

    @conversation.update!(assignee: agent)
  end

  def assign_team(team_id)
    team = @account.teams.find_by(id: team_id)
    return unless team

    @conversation.update!(team: team)
  end

  def add_labels(label_names)
    labels = @account.labels.where(title: label_names)
    @conversation.labels << labels
  end

  def send_message(content)
    @conversation.messages.create!(
      account: @account,
      inbox: @conversation.inbox,
      message_type: :outgoing,
      content: content,
      sender: automation_bot
    )
  end

  def resolve_conversation
    @conversation.update!(status: :resolved)
  end

  def send_webhook(webhook_url)
    WebhookJob.perform_later(
      webhook_url,
      conversation_payload
    )
  end

  def automation_bot
    @account.agent_bots.find_by(name: 'Automation Bot') ||
      AgentBot.create!(account: @account, name: 'Automation Bot')
  end
end
```

### Event Listener

```ruby
# app/listeners/automation_rule_listener.rb
class AutomationRuleListener < BaseListener
  def conversation_created(event)
    process_rules(event, 'conversation_created')
  end

  def conversation_updated(event)
    process_rules(event, 'conversation_updated')
  end

  def message_created(event)
    process_rules(event, 'message_created')
  end

  private

  def process_rules(event, event_name)
    conversation = event.data[:conversation]
    message = event.data[:message]

    rules = conversation.account.automation_rules
                        .active
                        .where(event_name: event_name)

    rules.each do |rule|
      AutomationRules::ExecutorJob.perform_later(
        rule.id,
        conversation.id,
        message&.id
      )
    end
  end
end
```

### Executor Job

```ruby
# app/jobs/automation_rules/executor_job.rb
class AutomationRules::ExecutorJob < ApplicationJob
  queue_as :default

  def perform(rule_id, conversation_id, message_id = nil)
    rule = AutomationRule.find_by(id: rule_id)
    conversation = Conversation.find_by(id: conversation_id)
    message = Message.find_by(id: message_id)

    return unless rule && conversation

    conditions_match = AutomationRules::ConditionsFilterService.new(
      rule,
      conversation,
      message: message
    ).perform

    return unless conditions_match

    AutomationRules::ActionService.new(rule, conversation).perform

    log_execution(rule, conversation)
  end

  private

  def log_execution(rule, conversation)
    Rails.logger.info(
      "Automation rule '#{rule.name}' executed for conversation #{conversation.id}"
    )
  end
end
```

## Testing Automation Rules

```ruby
# spec/services/automation_rules/conditions_filter_service_spec.rb
require 'rails_helper'

RSpec.describe AutomationRules::ConditionsFilterService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :open) }
  
  let(:rule) do
    create(:automation_rule,
      account: account,
      conditions: [
        { 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }
      ]
    )
  end

  subject { described_class.new(rule, conversation) }

  describe '#perform' do
    context 'when conditions match' do
      it 'returns true' do
        expect(subject.perform).to be true
      end
    end

    context 'when conditions do not match' do
      let(:conversation) { create(:conversation, account: account, status: :resolved) }

      it 'returns false' do
        expect(subject.perform).to be false
      end
    end
  end
end
```

## API Endpoints

```ruby
# app/controllers/api/v1/accounts/automation_rules_controller.rb
class Api::V1::Accounts::AutomationRulesController < Api::V1::Accounts::BaseController
  before_action :set_automation_rule, only: [:show, :update, :destroy]

  def index
    @automation_rules = Current.account.automation_rules
  end

  def create
    @automation_rule = Current.account.automation_rules.create!(automation_rule_params)
    render json: @automation_rule, status: :created
  end

  def update
    @automation_rule.update!(automation_rule_params)
    render json: @automation_rule
  end

  def destroy
    @automation_rule.destroy!
    head :no_content
  end

  private

  def automation_rule_params
    params.require(:automation_rule).permit(
      :name,
      :description,
      :event_name,
      :active,
      conditions: [:attribute_key, :filter_operator, values: []],
      actions: [:action_name, action_params: []]
    )
  end
end
```
