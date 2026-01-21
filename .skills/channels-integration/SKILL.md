---
name: channels-integration
description: Integrate messaging channels into Chatwoot such as WhatsApp, Facebook, Twitter, Telegram, and SMS. Use this skill when adding new channel integrations, modifying channel behavior, or handling channel-specific message formats.
metadata:
  author: chatwoot
  version: "1.0"
---

# Channels Integration

## Overview

Chatwoot supports multiple messaging channels. Each channel has its own model, service, and webhook handling.

## Channel Structure

```
app/
├── models/channel/
│   ├── api.rb
│   ├── email.rb
│   ├── facebook_page.rb
│   ├── line.rb
│   ├── sms.rb
│   ├── telegram.rb
│   ├── twilio_sms.rb
│   ├── twitter_profile.rb
│   ├── web_widget.rb
│   └── whatsapp.rb
├── services/
│   ├── whatsapp/
│   ├── telegram/
│   ├── twitter/
│   ├── facebook/
│   └── ...
└── controllers/webhooks/
    ├── whatsapp_controller.rb
    ├── telegram_controller.rb
    └── ...
```

## Channel Model Pattern

```ruby
# app/models/channel/whatsapp.rb
class Channel::Whatsapp < ApplicationRecord
  include Channelable
  
  self.table_name = 'channel_whatsapp'

  EDITABLE_ATTRS = [:phone_number, :provider, :provider_config].freeze

  validates :phone_number, presence: true, uniqueness: true
  validates :provider, presence: true

  enum provider: { default: 0, twilio: 1, '360dialog': 2 }

  def name
    'Whatsapp'
  end

  def messaging_window_enabled?
    true
  end

  def send_message(message)
    Whatsapp::SendMessageService.new(
      message: message,
      channel: self
    ).perform
  end
end
```

## Channelable Concern

```ruby
# app/models/concerns/channelable.rb
module Channelable
  extend ActiveSupport::Concern

  included do
    has_one :inbox, as: :channel, dependent: :destroy
    
    delegate :account, to: :inbox
  end

  def create_contact_inbox(contact)
    ContactInbox.find_or_create_by!(
      contact: contact,
      inbox: inbox,
      source_id: generate_source_id
    )
  end

  def has_24_hour_messaging_window?
    false
  end
end
```

## Creating a New Channel

### 1. Create Channel Model

```ruby
# app/models/channel/new_channel.rb
class Channel::NewChannel < ApplicationRecord
  include Channelable
  
  self.table_name = 'channel_new_channel'
  
  EDITABLE_ATTRS = [:api_key, :channel_id].freeze

  validates :api_key, presence: true
  validates :channel_id, presence: true, uniqueness: true

  def name
    'New Channel'
  end

  def send_message(message)
    NewChannel::SendMessageService.new(
      message: message,
      channel: self
    ).perform
  end
end
```

### 2. Create Migration

```ruby
# db/migrate/xxx_create_channel_new_channel.rb
class CreateChannelNewChannel < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_new_channel do |t|
      t.string :api_key, null: false
      t.string :channel_id, null: false
      t.jsonb :additional_config, default: {}
      t.timestamps
    end

    add_index :channel_new_channel, :channel_id, unique: true
  end
end
```

### 3. Create Send Message Service

```ruby
# app/services/new_channel/send_message_service.rb
class NewChannel::SendMessageService
  def initialize(message:, channel:)
    @message = message
    @channel = channel
  end

  def perform
    response = send_to_api
    
    if response.success?
      update_message_status(:delivered)
    else
      update_message_status(:failed, response.error)
    end
  end

  private

  def send_to_api
    NewChannel::Api.new(@channel.api_key).send_message(
      to: recipient_id,
      content: @message.content,
      attachments: build_attachments
    )
  end

  def recipient_id
    @message.conversation.contact_inbox.source_id
  end

  def build_attachments
    @message.attachments.map do |attachment|
      { type: attachment.file_type, url: attachment.download_url }
    end
  end

  def update_message_status(status, error = nil)
    @message.update!(
      status: status,
      external_error: error
    )
  end
end
```

### 4. Create Webhook Controller

```ruby
# app/controllers/webhooks/new_channel_controller.rb
class Webhooks::NewChannelController < ActionController::API
  def receive
    NewChannel::WebhookProcessorService.new(params).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error("NewChannel webhook error: #{e.message}")
    head :unprocessable_entity
  end
end
```

### 5. Create Webhook Processor

```ruby
# app/services/new_channel/webhook_processor_service.rb
class NewChannel::WebhookProcessorService
  def initialize(params)
    @params = params
  end

  def perform
    return unless valid_webhook?

    case event_type
    when 'message'
      process_incoming_message
    when 'delivery'
      process_delivery_status
    when 'read'
      process_read_status
    end
  end

  private

  def valid_webhook?
    # Validate webhook signature
    true
  end

  def event_type
    @params[:event_type]
  end

  def process_incoming_message
    channel = find_channel
    contact_inbox = find_or_create_contact_inbox(channel)
    conversation = find_or_create_conversation(contact_inbox)
    
    create_message(conversation)
  end

  def find_channel
    Channel::NewChannel.find_by!(channel_id: @params[:channel_id])
  end

  def find_or_create_contact_inbox(channel)
    contact = Contact.find_or_create_by!(
      account: channel.account,
      phone_number: @params[:from]
    ) do |c|
      c.name = @params[:from_name] || @params[:from]
    end

    channel.create_contact_inbox(contact)
  end

  def find_or_create_conversation(contact_inbox)
    Conversation.find_or_create_by!(
      account: contact_inbox.inbox.account,
      inbox: contact_inbox.inbox,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox
    )
  end

  def create_message(conversation)
    conversation.messages.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      content: @params[:content],
      message_type: :incoming,
      sender: conversation.contact,
      source_id: @params[:message_id]
    )
  end
end
```

### 6. Add Routes

```ruby
# config/routes.rb
namespace :webhooks do
  post 'new_channel', to: 'new_channel#receive'
end
```

## Channel-Specific Patterns

### WhatsApp (360dialog/Twilio)

- 24-hour messaging window
- Template messages for outbound initiation
- Media handling with separate upload

### Telegram

- Bot-based integration
- Inline keyboards support
- Group chat support

### Twitter

- OAuth-based connection
- Direct message API
- Tweet replies

### Facebook

- Page access token
- Message tags for sending outside window
- Messenger-specific features

## Testing Channels

```ruby
# spec/models/channel/new_channel_spec.rb
require 'rails_helper'

RSpec.describe Channel::NewChannel do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:api_key) }
    it { is_expected.to validate_presence_of(:channel_id) }
  end

  describe '#send_message' do
    let(:channel) { create(:channel_new_channel) }
    let(:message) { create(:message, inbox: channel.inbox) }

    it 'calls the send message service' do
      expect(NewChannel::SendMessageService)
        .to receive(:new)
        .with(message: message, channel: channel)
        .and_call_original

      channel.send_message(message)
    end
  end
end
```
