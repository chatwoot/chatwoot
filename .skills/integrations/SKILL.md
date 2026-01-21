---
name: integrations
description: Build and manage third-party integrations in Chatwoot including Slack, Dialogflow, OpenAI, webhooks, and custom apps. Use this skill when adding new integrations or extending existing ones.
metadata:
  author: chatwoot
  version: "1.0"
---

# Integrations Development

## Overview

Chatwoot supports various integrations: chat bots (Dialogflow, OpenAI), team tools (Slack, Linear), CRM connectors, and custom webhooks.

## Structure

```
lib/integrations/
├── bot_processor_service.rb      # Base bot processor
├── dialogflow/                   # Dialogflow integration
├── openai/                       # OpenAI/GPT integration
├── slack/                        # Slack integration
├── linear/                       # Linear integration
├── google_translate/             # Translation
└── dyte/                         # Video calling

app/models/integrations/
├── hook.rb                       # Webhook/integration hooks

app/services/
├── integrations/                 # Integration services
```

## Integration Hooks

### Hook Model

```ruby
# app/models/integrations/hook.rb
class Integrations::Hook < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true

  validates :app_id, presence: true
  validates :account_id, presence: true

  # Integration types
  TYPES = %w[slack dialogflow openai linear dyte captain].freeze

  scope :slack, -> { where(app_id: 'slack') }
  scope :dialogflow, -> { where(app_id: 'dialogflow') }

  store_accessor :settings, :api_key, :project_id, :webhook_url
end
```

## Creating a New Integration

### 1. Define Integration Config

```ruby
# config/integrations.yml
integrations:
  my_integration:
    name: My Integration
    description: Connect with My Service
    logo: my_integration.png
    fields:
      - name: api_key
        type: password
        required: true
        label: API Key
      - name: webhook_url
        type: text
        required: false
        label: Webhook URL
    hooks:
      - account
      - inbox
```

### 2. Create Integration Service

```ruby
# app/services/integrations/my_integration/send_service.rb
class Integrations::MyIntegration::SendService
  def initialize(hook:, message:)
    @hook = hook
    @message = message
    @conversation = message.conversation
  end

  def perform
    return unless should_process?

    response = send_to_service
    handle_response(response)
  end

  private

  def should_process?
    @hook.active? && @message.incoming?
  end

  def send_to_service
    client.send_message(
      conversation_id: @conversation.id,
      content: @message.content,
      metadata: build_metadata
    )
  end

  def client
    @client ||= MyIntegration::Client.new(
      api_key: @hook.settings['api_key']
    )
  end

  def build_metadata
    {
      contact_name: @conversation.contact.name,
      inbox_name: @conversation.inbox.name,
      account_id: @conversation.account_id
    }
  end

  def handle_response(response)
    return unless response.reply_content.present?

    create_reply_message(response.reply_content)
  end

  def create_reply_message(content)
    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      sender: integration_sender
    )
  end

  def integration_sender
    @hook.account.agent_bots.find_or_create_by!(name: 'My Integration Bot')
  end
end
```

### 3. Create Webhook Controller

```ruby
# app/controllers/webhooks/my_integration_controller.rb
class Webhooks::MyIntegrationController < ActionController::API
  before_action :verify_signature

  def receive
    hook = find_hook
    return head :not_found unless hook

    Integrations::MyIntegration::WebhookService.new(
      hook: hook,
      payload: webhook_params
    ).perform

    head :ok
  end

  private

  def verify_signature
    signature = request.headers['X-Signature']
    expected = compute_signature(request.raw_post)
    
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end

  def find_hook
    Integrations::Hook.find_by(
      app_id: 'my_integration',
      settings: { webhook_id: params[:webhook_id] }
    )
  end

  def compute_signature(payload)
    OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload)
  end

  def webhook_secret
    ENV.fetch('MY_INTEGRATION_WEBHOOK_SECRET')
  end
end
```

## Slack Integration

### Sending to Slack

```ruby
# lib/integrations/slack/send_on_slack_service.rb
class Integrations::Slack::SendOnSlackService
  def initialize(message:, hook:)
    @message = message
    @hook = hook
    @conversation = message.conversation
  end

  def perform
    return unless should_send?

    if @conversation.identifier.present?
      send_thread_reply
    else
      create_new_thread
    end
  end

  private

  def should_send?
    @hook.active? && @message.outgoing?
  end

  def send_thread_reply
    client.chat_postMessage(
      channel: channel_id,
      thread_ts: @conversation.identifier,
      text: formatted_message,
      unfurl_links: true
    )
  end

  def create_new_thread
    response = client.chat_postMessage(
      channel: channel_id,
      text: formatted_message,
      attachments: conversation_attachments
    )

    @conversation.update!(identifier: response['ts'])
  end

  def client
    @client ||= Slack::Web::Client.new(token: @hook.access_token)
  end

  def channel_id
    @hook.settings['channel_id']
  end

  def formatted_message
    "*#{sender_name}*: #{@message.content}"
  end

  def sender_name
    @message.sender&.name || 'Agent'
  end
end
```

### Receiving from Slack

```ruby
# app/services/integrations/slack/incoming_message_service.rb
class Integrations::Slack::IncomingMessageService
  def initialize(params:)
    @params = params
    @event = params[:event]
  end

  def perform
    return unless valid_event?

    conversation = find_conversation
    return unless conversation

    create_incoming_message(conversation)
  end

  private

  def valid_event?
    @event[:type] == 'message' && @event[:thread_ts].present?
  end

  def find_conversation
    Conversation.find_by(identifier: @event[:thread_ts])
  end

  def create_incoming_message(conversation)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      content: @event[:text],
      external_source_ids: { slack_user: @event[:user] }
    )
  end
end
```

## OpenAI/LLM Integration

```ruby
# lib/integrations/openai/processor_service.rb
class Integrations::Openai::ProcessorService
  def initialize(hook:, message:)
    @hook = hook
    @message = message
    @conversation = message.conversation
  end

  def perform
    return unless should_process?

    response = generate_response
    create_reply(response) if response.present?
  end

  private

  def should_process?
    @hook.active? && @message.incoming?
  end

  def generate_response
    client.chat(
      parameters: {
        model: model_name,
        messages: build_messages,
        max_tokens: 500,
        temperature: 0.7
      }
    ).dig('choices', 0, 'message', 'content')
  end

  def build_messages
    system_message + conversation_history
  end

  def system_message
    [{
      role: 'system',
      content: @hook.settings['system_prompt'] || default_prompt
    }]
  end

  def conversation_history
    @conversation.messages
                 .order(created_at: :desc)
                 .limit(10)
                 .reverse
                 .map { |m| { role: message_role(m), content: m.content } }
  end

  def message_role(message)
    message.incoming? ? 'user' : 'assistant'
  end

  def client
    @client ||= OpenAI::Client.new(access_token: @hook.settings['api_key'])
  end

  def model_name
    @hook.settings['model'] || 'gpt-4'
  end

  def default_prompt
    "You are a helpful customer support assistant for #{@conversation.account.name}."
  end

  def create_reply(content)
    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      sender: ai_bot
    )
  end

  def ai_bot
    @hook.account.agent_bots.find_or_create_by!(name: 'AI Assistant')
  end
end
```

## Webhook Integration

### Outgoing Webhooks

```ruby
# app/services/webhooks/trigger_service.rb
class Webhooks::TriggerService
  EVENTS = %w[
    conversation_created
    conversation_status_changed
    conversation_updated
    message_created
    message_updated
    webwidget_triggered
  ].freeze

  def initialize(event:, data:)
    @event = event
    @data = data
    @account = data[:account]
  end

  def perform
    return unless EVENTS.include?(@event)

    webhooks.each do |webhook|
      WebhookJob.perform_later(webhook.id, build_payload)
    end
  end

  private

  def webhooks
    @account.webhooks
            .active
            .where('subscriptions @> ?', [@event].to_json)
  end

  def build_payload
    {
      event: @event,
      timestamp: Time.current.to_i,
      data: serialized_data
    }
  end

  def serialized_data
    case @event
    when /^conversation/
      ConversationSerializer.new(@data[:conversation]).as_json
    when /^message/
      MessageSerializer.new(@data[:message]).as_json
    end
  end
end

# app/jobs/webhook_job.rb
class WebhookJob < ApplicationJob
  queue_as :webhooks
  
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(webhook_id, payload)
    webhook = Webhook.find_by(id: webhook_id)
    return unless webhook

    response = deliver(webhook, payload)
    log_delivery(webhook, response)
  end

  private

  def deliver(webhook, payload)
    HTTParty.post(
      webhook.url,
      body: payload.to_json,
      headers: headers(webhook),
      timeout: 10
    )
  end

  def headers(webhook)
    {
      'Content-Type' => 'application/json',
      'X-Chatwoot-Signature' => compute_signature(payload, webhook.secret)
    }
  end

  def compute_signature(payload, secret)
    OpenSSL::HMAC.hexdigest('SHA256', secret, payload.to_json)
  end
end
```

## Testing Integrations

```ruby
# spec/services/integrations/slack/send_on_slack_service_spec.rb
require 'rails_helper'

RSpec.describe Integrations::Slack::SendOnSlackService do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :slack, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, conversation: conversation, message_type: :outgoing) }

  subject(:service) { described_class.new(message: message, hook: hook) }

  describe '#perform' do
    let(:slack_client) { instance_double(Slack::Web::Client) }

    before do
      allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    end

    context 'when conversation has no Slack thread' do
      it 'creates new thread' do
        expect(slack_client).to receive(:chat_postMessage)
          .and_return({ 'ts' => '1234.5678' })

        service.perform

        expect(conversation.reload.identifier).to eq('1234.5678')
      end
    end

    context 'when conversation has Slack thread' do
      let(:conversation) { create(:conversation, account: account, identifier: '1234.5678') }

      it 'replies to thread' do
        expect(slack_client).to receive(:chat_postMessage)
          .with(hash_including(thread_ts: '1234.5678'))

        service.perform
      end
    end
  end
end
```
