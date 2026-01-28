---
name: webhooks-events
description: Implement webhook handling and event dispatching in Chatwoot. Use this skill when processing incoming webhooks, dispatching events, or building event-driven features.
metadata:
  author: chatwoot
  version: "1.0"
---

# Webhooks & Events

## Overview

Chatwoot uses an event-driven architecture with listeners for internal events and webhooks for external integrations.

## Structure

```
lib/
├── events/
│   └── types.rb              # Event type definitions
├── webhooks/
│   └── trigger.rb            # Webhook trigger logic

app/
├── listeners/                 # Event listeners
│   ├── base_listener.rb
│   ├── action_cable_listener.rb
│   ├── automation_rule_listener.rb
│   ├── hook_listener.rb
│   └── webhook_listener.rb
├── dispatchers/               # Event dispatchers
│   └── async_dispatcher.rb
├── models/
│   └── webhook.rb            # Webhook model
```

## Event Types

```ruby
# lib/events/types.rb
module Events
  module Types
    # Conversation events
    CONVERSATION_CREATED = 'conversation.created'
    CONVERSATION_UPDATED = 'conversation.updated'
    CONVERSATION_STATUS_CHANGED = 'conversation.status_changed'
    CONVERSATION_ASSIGNED = 'conversation.assigned'
    CONVERSATION_RESOLVED = 'conversation.resolved'
    CONVERSATION_REOPENED = 'conversation.reopened'

    # Message events
    MESSAGE_CREATED = 'message.created'
    MESSAGE_UPDATED = 'message.updated'

    # Contact events
    CONTACT_CREATED = 'contact.created'
    CONTACT_UPDATED = 'contact.updated'

    # Agent events
    AGENT_ADDED = 'agent.added'
    AGENT_REMOVED = 'agent.removed'

    ALL_EVENTS = [
      CONVERSATION_CREATED,
      CONVERSATION_UPDATED,
      CONVERSATION_STATUS_CHANGED,
      CONVERSATION_ASSIGNED,
      MESSAGE_CREATED,
      MESSAGE_UPDATED,
      CONTACT_CREATED,
      CONTACT_UPDATED
    ].freeze
  end
end
```

## Dispatching Events

### Rails Event Dispatch

```ruby
# Publishing events
Rails.configuration.dispatcher.dispatch(
  Events::Types::CONVERSATION_CREATED,
  Time.zone.now,
  conversation: conversation,
  account: account
)

# In a service
class Conversations::CreateService
  def perform
    conversation = create_conversation
    
    dispatch_event(conversation)
    
    conversation
  end

  private

  def dispatch_event(conversation)
    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONVERSATION_CREATED,
      Time.zone.now,
      conversation: conversation,
      account: conversation.account,
      inbox: conversation.inbox
    )
  end
end
```

### Async Dispatcher

```ruby
# app/dispatchers/async_dispatcher.rb
class AsyncDispatcher < BaseDispatcher
  def dispatch(event_name, timestamp, data)
    EventDispatchJob.perform_later(event_name, timestamp.to_i, data)
  end
end

# app/jobs/event_dispatch_job.rb
class EventDispatchJob < ApplicationJob
  queue_as :default

  def perform(event_name, timestamp, data)
    Rails.configuration.dispatcher.dispatch(
      event_name,
      Time.zone.at(timestamp),
      data.deep_symbolize_keys
    )
  end
end
```

## Event Listeners

### Base Listener

```ruby
# app/listeners/base_listener.rb
class BaseListener
  def self.inherited(subclass)
    Rails.configuration.dispatcher.subscribe(subclass.new)
  end

  def extract_data(event)
    event.data
  end

  def extract_account(event)
    event.data[:account]
  end
end
```

### ActionCable Listener

```ruby
# app/listeners/action_cable_listener.rb
class ActionCableListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    broadcast_to_account(conversation.account, event.name, conversation)
  end

  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    # Broadcast to conversation channel
    broadcast_to_conversation(conversation, event.name, message)

    # Broadcast to account channel
    broadcast_to_account(conversation.account, 'conversation.updated', conversation)
  end

  def conversation_status_changed(event)
    conversation = event.data[:conversation]
    broadcast_to_account(conversation.account, event.name, conversation)
    broadcast_to_conversation(conversation, event.name, conversation)
  end

  private

  def broadcast_to_account(account, event, data)
    ActionCable.server.broadcast(
      "account_#{account.id}",
      event: event,
      data: serialize(data)
    )
  end

  def broadcast_to_conversation(conversation, event, data)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      event: event,
      data: serialize(data)
    )
  end

  def serialize(data)
    case data
    when Conversation
      ConversationPresenter.new(data).as_json
    when Message
      MessagePresenter.new(data).as_json
    else
      data.as_json
    end
  end
end
```

### Webhook Listener

```ruby
# app/listeners/webhook_listener.rb
class WebhookListener < BaseListener
  def conversation_created(event)
    trigger_webhooks(event, Events::Types::CONVERSATION_CREATED)
  end

  def conversation_status_changed(event)
    trigger_webhooks(event, Events::Types::CONVERSATION_STATUS_CHANGED)
  end

  def message_created(event)
    trigger_webhooks(event, Events::Types::MESSAGE_CREATED)
  end

  private

  def trigger_webhooks(event, event_type)
    account = extract_account(event)
    return unless account

    webhooks = account.webhooks.active.subscribed_to(event_type)

    webhooks.find_each do |webhook|
      WebhookDeliveryJob.perform_later(
        webhook.id,
        build_payload(event, event_type)
      )
    end
  end

  def build_payload(event, event_type)
    {
      event: event_type,
      timestamp: Time.current.to_i,
      account: { id: event.data[:account].id },
      data: serialize_event_data(event)
    }
  end

  def serialize_event_data(event)
    data = event.data.dup
    
    data[:conversation] = ConversationSerializer.new(data[:conversation]).as_json if data[:conversation]
    data[:message] = MessageSerializer.new(data[:message]).as_json if data[:message]
    
    data.except(:account)
  end
end
```

### Automation Rule Listener

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
    account = extract_account(event)

    rules = account.automation_rules
                   .active
                   .where(event_name: event_name)

    rules.each do |rule|
      AutomationRules::ExecutorJob.perform_later(
        rule.id,
        conversation.id,
        event.data[:message]&.id
      )
    end
  end
end
```

## Webhook Model

```ruby
# app/models/webhook.rb
class Webhook < ApplicationRecord
  belongs_to :account

  validates :url, presence: true, url: true
  validates :subscriptions, presence: true

  scope :active, -> { where(active: true) }
  scope :subscribed_to, ->(event) { where('subscriptions @> ?', [event].to_json) }

  # Available subscriptions
  SUBSCRIPTION_EVENTS = Events::Types::ALL_EVENTS

  def subscribed_to?(event)
    subscriptions.include?(event)
  end
end
```

## Webhook Delivery

```ruby
# app/jobs/webhook_delivery_job.rb
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks
  
  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(webhook_id, payload)
    @webhook = Webhook.find(webhook_id)
    @payload = payload

    response = deliver_webhook

    log_delivery(response)
    handle_response(response)
  end

  private

  def deliver_webhook
    HTTParty.post(
      @webhook.url,
      body: @payload.to_json,
      headers: request_headers,
      timeout: 10
    )
  rescue StandardError => e
    OpenStruct.new(success?: false, code: 0, body: e.message)
  end

  def request_headers
    {
      'Content-Type' => 'application/json',
      'User-Agent' => 'Chatwoot-Webhooks/1.0',
      'X-Chatwoot-Signature' => compute_signature
    }
  end

  def compute_signature
    return '' unless @webhook.secret.present?

    OpenSSL::HMAC.hexdigest(
      'SHA256',
      @webhook.secret,
      @payload.to_json
    )
  end

  def log_delivery(response)
    Rails.logger.info(
      "Webhook delivered to #{@webhook.url}: #{response.code}"
    )
  end

  def handle_response(response)
    unless response.success?
      raise "Webhook delivery failed: #{response.code} - #{response.body}"
    end
  end
end
```

## Incoming Webhooks Controller

```ruby
# app/controllers/webhooks/base_controller.rb
class Webhooks::BaseController < ActionController::API
  before_action :verify_signature

  private

  def verify_signature
    return if skip_signature_verification?

    signature = request.headers['X-Signature'] || request.headers['X-Hub-Signature-256']
    return head :unauthorized unless signature

    expected = compute_expected_signature
    
    unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      head :unauthorized
    end
  end

  def compute_expected_signature
    OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, request.raw_post)
  end

  def webhook_secret
    raise NotImplementedError
  end

  def skip_signature_verification?
    false
  end
end

# app/controllers/webhooks/stripe_controller.rb
class Webhooks::StripeController < Webhooks::BaseController
  def receive
    event = Stripe::Webhook.construct_event(
      request.body.read,
      request.headers['Stripe-Signature'],
      webhook_secret
    )

    handle_event(event)
    head :ok
  rescue Stripe::SignatureVerificationError
    head :unauthorized
  end

  private

  def handle_event(event)
    case event.type
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object)
    end
  end

  def webhook_secret
    ENV.fetch('STRIPE_WEBHOOK_SECRET')
  end
end
```

## Testing Events

```ruby
# spec/listeners/webhook_listener_spec.rb
require 'rails_helper'

RSpec.describe WebhookListener do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:webhook) do
    create(:webhook,
      account: account,
      subscriptions: [Events::Types::CONVERSATION_CREATED]
    )
  end

  describe '#conversation_created' do
    let(:event) do
      Events::Base.new(
        Events::Types::CONVERSATION_CREATED,
        Time.current,
        conversation: conversation,
        account: account
      )
    end

    it 'enqueues webhook delivery job' do
      expect {
        described_class.new.conversation_created(event)
      }.to have_enqueued_job(WebhookDeliveryJob)
        .with(webhook.id, hash_including(event: Events::Types::CONVERSATION_CREATED))
    end

    context 'when webhook is not subscribed to event' do
      let!(:webhook) do
        create(:webhook,
          account: account,
          subscriptions: [Events::Types::MESSAGE_CREATED]
        )
      end

      it 'does not enqueue job' do
        expect {
          described_class.new.conversation_created(event)
        }.not_to have_enqueued_job(WebhookDeliveryJob)
      end
    end
  end
end
```
