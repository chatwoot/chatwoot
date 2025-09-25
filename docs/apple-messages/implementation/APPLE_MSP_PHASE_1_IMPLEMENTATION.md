# Apple Messages for Business - Phase 1 Implementation Guide

## ✅ **PHASE 1 STATUS: COMPLETE BUT NOT INTEGRATED**

**🚨 CRITICAL ISSUE**: Phase 1 implementation is **functionally complete** but **not integrated** with Chatwoot's core routing system. The channel exists but is not accessible through normal Chatwoot workflows.

### 🎉 **COMPLETED FEATURES**
✅ **List Picker with Full Image Support** - Successfully implemented and tested on Apple Messages devices!  
✅ **Time Picker** - Advanced scheduling with timezone support  
✅ **Quick Reply** - Button-based response system  
✅ **Rich Link Previews** - Open Graph link rendering  
✅ **Channel Management** - Complete MSP credential setup  
✅ **Webhook Processing** - JWT-authenticated message reception  
✅ **Frontend Components** - Message bubbles and composer interface  

📋 **See Complete Implementation Guide:** [`APPLE_MESSAGES_LIST_PICKER_IMPLEMENTATION.md`](APPLE_MESSAGES_LIST_PICKER_IMPLEMENTATION.md)

### ⚠️ **CRITICAL INTEGRATION GAPS**

**The implementation works but is not connected to Chatwoot's routing system:**

#### **Backend Integration Missing**
```ruby
# ❌ NOT ADDED: app/controllers/api/v1/accounts/inboxes_controller.rb
def allowed_channel_types
  %w[web_widget api email line telegram whatsapp sms] # missing: apple_messages_for_business
end

# ❌ NOT ADDED: app/jobs/send_reply_job.rb  
services = {
  # missing: 'Channel::AppleMessagesForBusiness' => AppleMessagesForBusiness::SendOnAppleMessagesForBusinessService
}

# ❌ NOT ADDED: config/routes.rb
# missing: post 'webhooks/apple_messages_for_business/:msp_id', to: 'webhooks/apple_messages_for_business#process_payload'
```

#### **Frontend Integration Missing**  
```javascript
// ❌ NOT ADDED: app/javascript/dashboard/helper/inbox.js
export const INBOX_TYPES = {
  // missing: APPLE_MESSAGES_FOR_BUSINESS: 'Channel::AppleMessagesForBusiness'
};

// ❌ NOT ADDED: app/javascript/dashboard/composables/useInbox.js
const INBOX_FEATURES = {
  // missing: [INBOX_FEATURES.INTERACTIVE_MESSAGES]: [INBOX_TYPES.APPLE_MESSAGES_FOR_BUSINESS]
};
```

### 📋 **IMMEDIATE ACTION REQUIRED**

**Priority: URGENT** - 1-2 hours to fix integration
1. Update `InboxesController` to include `apple_messages_for_business` in allowed types
2. Add webhook route in `config/routes.rb`  
3. Register service in `SendReplyJob`
4. Add channel to frontend inbox types and features
5. Test channel creation through Chatwoot UI

**Without these fixes, the channel cannot be:**
- Created through Chatwoot's admin interface
- Used to send/receive messages in conversations
- Accessed by agents or administrators

## Phase 1: Foundation & Basic Messaging (Weeks 1-3)

This document provides detailed implementation steps for Phase 1 of the Apple Messages for Business integration into Chatwoot.

## 1. Database Schema & Migration

### 1.1 Create Migration File
```bash
rails generate migration CreateChannelAppleMessagesForBusiness
```

### 1.2 Migration Implementation
```ruby
# db/migrate/xxx_create_channel_apple_messages_for_business.rb
class CreateChannelAppleMessagesForBusiness < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_apple_messages_for_business do |t|
      t.string :msp_id, null: false
      t.string :business_id, null: false
      t.text :secret, null: false
      t.string :merchant_id
      t.text :apple_pay_merchant_cert
      t.string :webhook_url
      t.string :imessage_extension_bid, default: 'com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension'
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_apple_messages_for_business, :msp_id, unique: true
    add_index :channel_apple_messages_for_business, :business_id, unique: true
    add_index :channel_apple_messages_for_business, :account_id
  end
end
```

## 2. Channel Model Implementation

### 2.1 Channel Model
```ruby
# app/models/channel/apple_messages_for_business.rb
class Channel::AppleMessagesForBusiness < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_apple_messages_for_business'
  EDITABLE_ATTRS = [
    :msp_id, :business_id, :secret, :merchant_id, 
    :apple_pay_merchant_cert, :webhook_url, :imessage_extension_bid,
    { provider_config: {} }
  ].freeze

  validates :msp_id, presence: true, uniqueness: true
  validates :business_id, presence: true, uniqueness: true
  validates :secret, presence: true
  validate :validate_jwt_credentials

  before_save :setup_webhook_url
  after_create :register_webhook

  def name
    'Apple Messages for Business'
  end

  def send_message(destination_id, message)
    AppleMessagesForBusiness::SendMessageService.new(
      channel: self,
      destination_id: destination_id,
      message: message
    ).perform
  end

  def generate_jwt_token
    AppleMessagesForBusiness::JwtService.generate_token(msp_id, secret)
  end

  def verify_jwt_token(token)
    AppleMessagesForBusiness::JwtService.verify_token(token, msp_id, secret)
  end

  def apple_pay_enabled?
    merchant_id.present? && apple_pay_merchant_cert.present?
  end

  private

  def validate_jwt_credentials
    return unless msp_id.present? && secret.present?

    begin
      token = generate_jwt_token
      verify_jwt_token(token)
    rescue StandardError => e
      errors.add(:secret, "Invalid JWT credentials: #{e.message}")
    end
  end

  def setup_webhook_url
    return if webhook_url.present?
    
    self.webhook_url = "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/apple_messages_for_business/#{msp_id}"
  end

  def register_webhook
    # Apple MSP doesn't require explicit webhook registration
    # Webhook URL is configured in Apple Business Register
    Rails.logger.info "Apple Messages for Business channel created for MSP ID: #{msp_id}"
  end
end
```

## 3. JWT Authentication Service

### 3.1 JWT Service Implementation
```ruby
# app/services/apple_messages_for_business/jwt_service.rb
class AppleMessagesForBusiness::JwtService
  class << self
    def generate_token(msp_id, secret)
      payload = {
        iss: msp_id,
        iat: Time.current.to_i
      }
      
      JWT.encode(
        payload,
        Base64.decode64(secret),
        'HS256',
        { alg: 'HS256' }
      )
    end

    def verify_token(token, msp_id, secret)
      JWT.decode(
        token,
        Base64.decode64(secret),
        true,
        { 
          algorithm: 'HS256',
          aud: msp_id,
          verify_aud: true
        }
      )
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT verification failed: #{e.message}"
      raise
    end
  end
end
```

## 4. Webhook Controller

### 4.1 Webhook Controller Implementation
```ruby
# app/controllers/webhooks/apple_messages_for_business_controller.rb
class Webhooks::AppleMessagesForBusinessController < ActionController::API
  before_action :find_channel
  before_action :verify_jwt_token
  before_action :decompress_payload

  def process_payload
    Webhooks::AppleMessagesForBusinessEventsJob.perform_later(
      @channel.id,
      @decompressed_payload,
      extract_headers
    )
    head :ok
  rescue StandardError => e
    Rails.logger.error "Apple Messages webhook error: #{e.message}"
    head :bad_request
  end

  private

  def find_channel
    msp_id = params[:msp_id]
    @channel = Channel::AppleMessagesForBusiness.find_by(msp_id: msp_id)
    
    unless @channel
      Rails.logger.warn "Channel not found for MSP ID: #{msp_id}"
      head :not_found
      return
    end
  end

  def verify_jwt_token
    auth_header = request.headers['Authorization']
    unless auth_header&.start_with?('Bearer ')
      Rails.logger.warn "Missing or invalid Authorization header"
      head :unauthorized
      return
    end

    token = auth_header.sub('Bearer ', '')
    @channel.verify_jwt_token(token)
  rescue JWT::DecodeError
    Rails.logger.warn "JWT verification failed for MSP ID: #{@channel.msp_id}"
    head :forbidden
  end

  def decompress_payload
    compressed_data = request.body.read
    
    if compressed_data.empty?
      @decompressed_payload = {}
      return
    end

    begin
      @decompressed_payload = decompress_gzip(compressed_data)
    rescue StandardError => e
      Rails.logger.error "Payload decompression failed: #{e.message}"
      head :bad_request
    end
  end

  def decompress_gzip(data)
    gz = Zlib::GzipReader.new(StringIO.new(data))
    JSON.parse(gz.read)
  ensure
    gz&.close
  end

  def extract_headers
    {
      source_id: request.headers['source-id'],
      destination_id: request.headers['destination-id'],
      capability_list: request.headers['capability-list']
    }
  end
end
```

## 5. Background Job Processing

### 5.1 Events Job Implementation
```ruby
# app/jobs/webhooks/apple_messages_for_business_events_job.rb
class Webhooks::AppleMessagesForBusinessEventsJob < ApplicationJob
  queue_as :default

  def perform(channel_id, payload, headers)
    channel = Channel::AppleMessagesForBusiness.find(channel_id)
    
    return unless channel_active?(channel)

    process_message_event(channel, payload, headers)
  rescue StandardError => e
    Rails.logger.error "Apple Messages event processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def channel_active?(channel)
    return true if channel&.account&.active?

    Rails.logger.warn "Inactive channel or account for MSP ID: #{channel&.msp_id}"
    false
  end

  def process_message_event(channel, payload, headers)
    message_type = payload['type']

    case message_type
    when 'text', 'interactive'
      AppleMessagesForBusiness::IncomingMessageService.new(
        inbox: channel.inbox,
        params: payload,
        headers: headers
      ).perform
    when 'typing_start'
      process_typing_indicator(channel, payload, headers, :start)
    when 'typing_end'
      process_typing_indicator(channel, payload, headers, :end)
    when 'close'
      process_conversation_close(channel, payload, headers)
    else
      Rails.logger.warn "Unknown message type: #{message_type}"
    end
  end

  def process_typing_indicator(channel, payload, headers, status)
    # Create activity message for typing indicators
    AppleMessagesForBusiness::TypingIndicatorService.new(
      inbox: channel.inbox,
      params: payload,
      headers: headers,
      status: status
    ).perform
  end

  def process_conversation_close(channel, payload, headers)
    # Handle conversation close events
    AppleMessagesForBusiness::ConversationCloseService.new(
      inbox: channel.inbox,
      params: payload,
      headers: headers
    ).perform
  end
end
```

## 6. Incoming Message Service

### 6.1 Message Processing Service
```ruby
# app/services/apple_messages_for_business/incoming_message_service.rb
class AppleMessagesForBusiness::IncomingMessageService
  include ::FileTypeHelper

  def initialize(inbox:, params:, headers:)
    @inbox = inbox
    @params = params
    @headers = headers
  end

  def perform
    return unless valid_message?

    set_contact
    set_conversation
    create_message
    process_attachments if attachments_present?
    process_interactive_data if interactive_message?
  end

  private

  def valid_message?
    @params['id'].present? && (@params['body'].present? || @params['attachments'].present? || @params['interactiveData'].present?)
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def create_message
    @message = @conversation.messages.build(
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: message_sender,
      content_attributes: content_attributes,
      source_id: @params['id']
    )

    @message.save!
  end

  def source_id
    @headers[:source_id] || @params['sourceId']
  end

  def message_content
    case @params['type']
    when 'text'
      @params['body']
    when 'interactive'
      extract_interactive_content
    else
      ''
    end
  end

  def message_type
    case @params['type']
    when 'text', 'interactive'
      :incoming
    else
      :activity
    end
  end

  def message_sender
    @contact
  end

  def content_attributes
    attributes = {}
    
    if interactive_message?
      attributes.merge!(extract_interactive_attributes)
    end

    if @params['replyToMessageId'].present?
      attributes[:in_reply_to_external_id] = @params['replyToMessageId']
    end

    attributes
  end

  def contact_attributes
    {
      name: extract_contact_name,
      additional_attributes: {
        apple_messages_source_id: source_id
      }
    }
  end

  def extract_contact_name
    # Apple Messages doesn't provide contact name in payload
    # Use source_id as fallback
    "Apple User #{source_id[-8..-1]}"
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        apple_messages_source_id: source_id
      }
    }
  end

  def interactive_message?
    @params['type'] == 'interactive'
  end

  def attachments_present?
    @params['attachments'].present? && @params['attachments'].is_a?(Array)
  end

  def extract_interactive_content
    interactive_data = @params['interactiveData']
    return '' unless interactive_data

    # Extract meaningful content from interactive data
    if interactive_data['data']
      case interactive_data['data'].keys.first
      when 'listPicker'
        'List Picker Response'
      when 'timePicker'
        'Time Picker Response'
      when 'authenticate'
        'Authentication Response'
      when 'payment'
        'Payment Response'
      else
        'Interactive Message'
      end
    else
      'Interactive Message'
    end
  end

  def extract_interactive_attributes
    interactive_data = @params['interactiveData']
    return {} unless interactive_data

    {
      interactive_type: determine_interactive_type(interactive_data),
      interactive_data: interactive_data,
      bid: interactive_data['bid']
    }
  end

  def determine_interactive_type(interactive_data)
    return 'unknown' unless interactive_data['data']

    data_keys = interactive_data['data'].keys
    
    if data_keys.include?('listPicker')
      'list_picker'
    elsif data_keys.include?('timePicker')
      'time_picker'
    elsif data_keys.include?('authenticate')
      'authentication'
    elsif data_keys.include?('payment')
      'payment'
    elsif data_keys.include?('quick-reply')
      'quick_reply'
    else
      'custom'
    end
  end

  def process_attachments
    @params['attachments'].each do |attachment_data|
      create_attachment(attachment_data)
    end
  end

  def create_attachment(attachment_data)
    file_type = determine_file_type(attachment_data)
    
    @message.attachments.create!(
      account_id: @message.account_id,
      file_type: file_type,
      external_url: attachment_data['url'],
      fallback_title: attachment_data['name'],
      meta: {
        apple_attachment_data: attachment_data,
        signature: attachment_data['signature'],
        owner: attachment_data['owner'],
        decryption_key: attachment_data['key']
      }
    )
  end

  def determine_file_type(attachment_data)
    mime_type = attachment_data['mimeType']
    
    case mime_type
    when /^image\//
      :image
    when /^audio\//
      :audio
    when /^video\//
      :video
    else
      :file
    end
  end

  def process_interactive_data
    interactive_type = @message.content_attributes['interactive_type']
    
    case interactive_type
    when 'list_picker'
      process_list_picker_response
    when 'time_picker'
      process_time_picker_response
    when 'authentication'
      process_authentication_response
    when 'payment'
      process_payment_response
    end
  end

  def process_list_picker_response
    # Handle list picker selections
    Rails.logger.info "Processing list picker response for message #{@message.id}"
  end

  def process_time_picker_response
    # Handle time picker selections
    Rails.logger.info "Processing time picker response for message #{@message.id}"
  end

  def process_authentication_response
    # Handle authentication responses
    Rails.logger.info "Processing authentication response for message #{@message.id}"
  end

  def process_payment_response
    # Handle payment responses
    Rails.logger.info "Processing payment response for message #{@message.id}"
  end
end
```

## 7. Route Configuration

### 7.1 Add Routes
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ... existing routes

  # Apple Messages for Business webhook
  post 'webhooks/apple_messages_for_business/:msp_id', 
       to: 'webhooks/apple_messages_for_business#process_payload'
end
```

## 8. Controller Registration

### 8.1 Update InboxesController
```ruby
# app/controllers/api/v1/accounts/inboxes_controller.rb

# Add to allowed_channel_types method
def allowed_channel_types
  %w[web_widget api email line telegram whatsapp sms apple_messages_for_business]
end

# Add to channel_type_from_params method
def channel_type_from_params
  {
    'web_widget' => Channel::WebWidget,
    'api' => Channel::Api,
    'email' => Channel::Email,
    'line' => Channel::Line,
    'telegram' => Channel::Telegram,
    'whatsapp' => Channel::Whatsapp,
    'sms' => Channel::Sms,
    'apple_messages_for_business' => Channel::AppleMessagesForBusiness
  }[permitted_params[:channel][:type]]
end
```

## 9. Testing Setup

### 9.1 Model Tests
```ruby
# spec/models/channel/apple_messages_for_business_spec.rb
require 'rails_helper'

RSpec.describe Channel::AppleMessagesForBusiness, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:msp_id) }
    it { should validate_presence_of(:business_id) }
    it { should validate_presence_of(:secret) }
    it { should validate_uniqueness_of(:msp_id) }
    it { should validate_uniqueness_of(:business_id) }
  end

  describe 'associations' do
    it { should belong_to(:account) }
    it { should have_one(:inbox) }
  end

  describe '#generate_jwt_token' do
    let(:channel) { create(:channel_apple_messages_for_business) }
    
    it 'generates a valid JWT token' do
      token = channel.generate_jwt_token
      expect(token).to be_present
      expect { channel.verify_jwt_token(token) }.not_to raise_error
    end
  end

  describe '#apple_pay_enabled?' do
    let(:channel) { create(:channel_apple_messages_for_business) }
    
    context 'when merchant_id and certificate are present' do
      before do
        channel.update!(
          merchant_id: 'merchant.com.example',
          apple_pay_merchant_cert: 'certificate_content'
        )
      end
      
      it 'returns true' do
        expect(channel.apple_pay_enabled?).to be true
      end
    end
    
    context 'when merchant_id or certificate is missing' do
      it 'returns false' do
        expect(channel.apple_pay_enabled?).to be false
      end
    end
  end
end
```

### 9.2 Factory Definition
```ruby
# spec/factories/channel/apple_messages_for_business.rb
FactoryBot.define do
  factory :channel_apple_messages_for_business, class: 'Channel::AppleMessagesForBusiness' do
    sequence(:msp_id) { |n| "msp_id_#{n}" }
    sequence(:business_id) { |n| "business_id_#{n}" }
    secret { Base64.encode64('test_secret_key_32_characters_long') }
    account
  end
end
```

## 10. Deployment Checklist

### 10.1 Environment Variables
Add to your environment configuration:
```bash
# Apple Messages for Business Configuration
APPLE_MSP_GATEWAY_URL=https://mspgw.push.apple.com/v1
APPLE_PAY_GATEWAY_URL=https://apple-pay-gateway.apple.com/paymentservices/paymentSession
```

### 10.2 Database Migration
```bash
rails db:migrate
```

### 10.3 Restart Services
```bash
# Restart application server
# Restart background job processors
```

This completes Phase 1 implementation, providing the foundation for Apple Messages for Business integration with basic messaging capabilities.