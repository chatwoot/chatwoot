# Apple Messages for Business - Outgoing Message Services

## Outgoing Message Implementation

This document covers the implementation of outgoing message services for Apple Messages for Business integration.

## 1. Send Message Service

### 1.1 Base Send Service
```ruby
# app/services/apple_messages_for_business/send_on_apple_messages_for_business_service.rb
class AppleMessagesForBusiness::SendOnAppleMessagesForBusinessService < Base::SendOnChannelService
  private

  def channel_class
    Channel::AppleMessagesForBusiness
  end

  def perform_reply
    case message.content_type
    when 'text'
      send_text_message
    when 'apple_list_picker'
      send_list_picker_message
    when 'apple_time_picker'
      send_time_picker_message
    when 'apple_quick_reply'
      send_quick_reply_message
    else
      send_text_message # fallback
    end
  end

  def send_text_message
    service = AppleMessagesForBusiness::SendMessageService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_list_picker_message
    service = AppleMessagesForBusiness::SendListPickerService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_time_picker_message
    service = AppleMessagesForBusiness::SendTimePickerService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_quick_reply_message
    service = AppleMessagesForBusiness::SendQuickReplyService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def update_message_status(response)
    if response[:success]
      message.update!(source_id: response[:message_id])
    else
      message.update!(
        status: :failed,
        external_error: response[:error]
      )
    end
  end
end
```

### 1.2 Core Send Message Service
```ruby
# app/services/apple_messages_for_business/send_message_service.rb
class AppleMessagesForBusiness::SendMessageService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'

  def initialize(channel:, destination_id:, message:)
    @channel = channel
    @destination_id = destination_id
    @message = message
  end

  def perform
    case @message.content_type
    when 'text'
      send_text_message
    else
      send_text_message # fallback
    end
  rescue StandardError => e
    Rails.logger.error "Apple Messages send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def send_text_message
    message_id = SecureRandom.uuid
    
    payload = {
      id: message_id,
      type: 'text',
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1,
      body: @message.content,
      locale: 'en_US'
    }

    # Add attachments if present
    if @message.attachments.present?
      payload[:attachments] = process_attachments
    end

    response = send_to_apple_gateway(payload, message_id)
    
    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  end

  def process_attachments
    @message.attachments.map do |attachment|
      if attachment.file.attached?
        upload_attachment(attachment)
      else
        # Handle external attachments
        {
          name: attachment.fallback_title,
          url: attachment.external_url,
          mimeType: attachment.file.content_type || 'application/octet-stream'
        }
      end
    end.compact
  end

  def upload_attachment(attachment)
    file_data = attachment.file.download
    encrypted_data, decryption_key = AppleMessagesForBusiness::AttachmentCipherService.encrypt(file_data)
    
    # Pre-upload to get upload URL
    upload_info = pre_upload_attachment(encrypted_data.size)
    
    # Upload encrypted data
    upload_response = upload_to_mmcs(upload_info[:upload_url], encrypted_data)
    
    {
      name: attachment.file.filename.to_s,
      mimeType: attachment.file.content_type,
      size: encrypted_data.size.to_s,
      'signature-base64' => upload_response[:signature],
      url: upload_info[:mmcs_url],
      owner: upload_info[:mmcs_owner],
      key: decryption_key
    }
  rescue StandardError => e
    Rails.logger.error "Attachment upload failed: #{e.message}"
    nil
  end

  def pre_upload_attachment(size)
    headers = {
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'Source-Id' => @channel.business_id,
      'MMCS-Size' => size.to_s
    }

    response = HTTParty.get(
      "#{AMB_SERVER}/preUpload",
      headers: headers,
      timeout: 30
    )

    if response.success?
      {
        upload_url: response.parsed_response['upload-url'],
        mmcs_url: response.parsed_response['mmcs-url'],
        mmcs_owner: response.parsed_response['mmcs-owner']
      }
    else
      raise "Pre-upload failed: #{response.code} #{response.body}"
    end
  end

  def upload_to_mmcs(upload_url, encrypted_data)
    headers = {
      'Content-Length' => encrypted_data.size.to_s
    }

    response = HTTParty.post(
      upload_url,
      body: encrypted_data,
      headers: headers,
      timeout: 60
    )

    if response.success?
      {
        signature: response.parsed_response.dig('singleFile', 'fileChecksum')
      }
    else
      raise "MMCS upload failed: #{response.code} #{response.body}"
    end
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end
end
```

## 2. Interactive Message Services

### 2.1 List Picker Service
```ruby
# app/services/apple_messages_for_business/send_list_picker_service.rb
class AppleMessagesForBusiness::SendListPickerService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'

  def initialize(channel:, destination_id:, message:)
    @channel = channel
    @destination_id = destination_id
    @message = message
  end

  def perform
    message_id = SecureRandom.uuid
    request_id = SecureRandom.uuid

    interactive_data = build_list_picker_data(request_id)
    
    payload = {
      id: message_id,
      type: 'interactive',
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1,
      interactiveData: interactive_data
    }

    response = send_to_apple_gateway(payload, message_id)
    
    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  rescue StandardError => e
    Rails.logger.error "List picker send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def build_list_picker_data(request_id)
    content_attrs = @message.content_attributes
    
    {
      bid: @channel.imessage_extension_bid,
      data: {
        listPicker: {
          sections: build_sections(content_attrs['sections'] || [])
        },
        mspVersion: '1.0',
        requestIdentifier: request_id
      },
      receivedMessage: {
        style: content_attrs.dig('received_message', 'style') || 'small',
        title: content_attrs.dig('received_message', 'title') || @message.content,
        subtitle: content_attrs.dig('received_message', 'subtitle') || ''
      },
      replyMessage: {
        style: content_attrs.dig('reply_message', 'style') || 'small',
        title: content_attrs.dig('reply_message', 'title') || 'Selection Made',
        subtitle: content_attrs.dig('reply_message', 'subtitle') || ''
      }
    }
  end

  def build_sections(sections_data)
    sections_data.map.with_index do |section, index|
      {
        title: section['title'],
        order: index,
        multipleSelection: section['multiple_selection'] || false,
        items: build_section_items(section['items'] || [])
      }
    end
  end

  def build_section_items(items_data)
    items_data.map.with_index do |item, index|
      {
        identifier: item['identifier'] || index.to_s,
        order: index,
        style: item['style'] || 'default',
        title: item['title'],
        subtitle: item['subtitle'] || ''
      }.tap do |item_hash|
        item_hash[:imageIdentifier] = item['image_identifier'] if item['image_identifier']
      end
    end
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end
end
```

### 2.2 Time Picker Service
```ruby
# app/services/apple_messages_for_business/send_time_picker_service.rb
class AppleMessagesForBusiness::SendTimePickerService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'

  def initialize(channel:, destination_id:, message:)
    @channel = channel
    @destination_id = destination_id
    @message = message
  end

  def perform
    message_id = SecureRandom.uuid
    request_id = SecureRandom.uuid

    interactive_data = build_time_picker_data(request_id)
    
    payload = {
      id: message_id,
      type: 'interactive',
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1,
      interactiveData: interactive_data
    }

    response = send_to_apple_gateway(payload, message_id)
    
    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  rescue StandardError => e
    Rails.logger.error "Time picker send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def build_time_picker_data(request_id)
    content_attrs = @message.content_attributes
    
    {
      bid: @channel.imessage_extension_bid,
      data: {
        mspVersion: '1.0',
        requestIdentifier: request_id,
        event: build_event_data(content_attrs['event'] || {})
      },
      receivedMessage: {
        style: content_attrs.dig('received_message', 'style') || 'icon',
        title: content_attrs.dig('received_message', 'title') || @message.content,
        subtitle: content_attrs.dig('received_message', 'subtitle') || ''
      },
      replyMessage: {
        style: content_attrs.dig('reply_message', 'style') || 'icon',
        title: content_attrs.dig('reply_message', 'title') || 'Time Selected'
      }
    }
  end

  def build_event_data(event_data)
    {
      identifier: event_data['identifier'] || '1',
      title: event_data['title'] || '',
      timeslots: build_timeslots(event_data['timeslots'] || [])
    }.tap do |event_hash|
      event_hash[:timezoneOffset] = event_data['timezone_offset'] if event_data['timezone_offset']
    end
  end

  def build_timeslots(timeslots_data)
    timeslots_data.map.with_index do |slot, index|
      {
        identifier: slot['identifier'] || index.to_s,
        startTime: slot['start_time'],
        duration: slot['duration'] || 3600
      }
    end
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end
end
```

### 2.3 Quick Reply Service
```ruby
# app/services/apple_messages_for_business/send_quick_reply_service.rb
class AppleMessagesForBusiness::SendQuickReplyService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'

  def initialize(channel:, destination_id:, message:)
    @channel = channel
    @destination_id = destination_id
    @message = message
  end

  def perform
    message_id = SecureRandom.uuid
    request_id = SecureRandom.uuid

    interactive_data = build_quick_reply_data(request_id)
    
    payload = {
      id: message_id,
      type: 'interactive',
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1,
      interactiveData: interactive_data
    }

    response = send_to_apple_gateway(payload, message_id)
    
    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  rescue StandardError => e
    Rails.logger.error "Quick reply send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def build_quick_reply_data(request_id)
    content_attrs = @message.content_attributes
    
    {
      bid: @channel.imessage_extension_bid,
      data: {
        'quick-reply' => {
          summaryText: content_attrs['summary_text'] || @message.content,
          items: build_quick_reply_items(content_attrs['items'] || [])
        },
        version: '1.0',
        requestIdentifier: request_id
      }
    }
  end

  def build_quick_reply_items(items_data)
    items_data.map.with_index do |item, index|
      {
        identifier: item['identifier'] || (index + 1).to_s,
        title: item['title']
      }
    end
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end
end
```

## 3. Attachment Encryption Service

### 3.1 Attachment Cipher Service
```ruby
# app/services/apple_messages_for_business/attachment_cipher_service.rb
class AppleMessagesForBusiness::AttachmentCipherService
  class << self
    def encrypt(data)
      key = SecureRandom.random_bytes(32)
      decryption_key = "00#{key.unpack1('H*')}"
      
      # Use zero IV as per Apple specification
      iv = "\x00" * 16
      
      cipher = OpenSSL::Cipher.new('AES-256-CTR')
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      
      encrypted_data = cipher.update(data) + cipher.final
      
      [encrypted_data, decryption_key]
    end

    def decrypt(encrypted_data, decryption_key)
      # Remove '00' prefix and convert hex to binary
      key_hex = decryption_key[2..-1]
      key = [key_hex].pack('H*')
      
      # Use zero IV as per Apple specification
      iv = "\x00" * 16
      
      cipher = OpenSSL::Cipher.new('AES-256-CTR')
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      
      cipher.update(encrypted_data) + cipher.final
    end
  end
end
```

## 4. Job Integration

### 4.1 Update SendReplyJob
```ruby
# app/jobs/send_reply_job.rb
class SendReplyJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    channel_name = conversation.inbox.channel.class.to_s

    services = {
      'Channel::TwitterProfile' => ::Twitter::SendOnTwitterService,
      'Channel::TwilioSms' => ::Twilio::SendOnTwilioService,
      'Channel::Line' => ::Line::SendOnLineService,
      'Channel::Telegram' => ::Telegram::SendOnTelegramService,
      'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService,
      'Channel::Sms' => ::Sms::SendOnSmsService,
      'Channel::Instagram' => ::Instagram::SendOnInstagramService,
      'Channel::AppleMessagesForBusiness' => ::AppleMessagesForBusiness::SendOnAppleMessagesForBusinessService
    }

    case channel_name
    when 'Channel::FacebookPage'
      send_on_facebook_page(message)
    else
      services[channel_name].new(message: message).perform if services[channel_name].present?
    end
  end

  # ... rest of the class
end
```

## 5. Error Handling and Logging

### 5.1 Error Handler Service
```ruby
# app/services/apple_messages_for_business/error_handler_service.rb
class AppleMessagesForBusiness::ErrorHandlerService
  def self.handle_api_error(response, message)
    error_code = response.code
    error_body = response.body
    
    case error_code
    when 400
      handle_bad_request(error_body, message)
    when 401
      handle_unauthorized(error_body, message)
    when 403
      handle_forbidden(error_body, message)
    when 429
      handle_rate_limit(error_body, message)
    when 500..599
      handle_server_error(error_body, message)
    else
      handle_unknown_error(error_code, error_body, message)
    end
  end

  private

  def self.handle_bad_request(error_body, message)
    Rails.logger.error "Apple Messages Bad Request: #{error_body}"
    message.update!(
      status: :failed,
      external_error: "Invalid request: #{error_body}"
    )
  end

  def self.handle_unauthorized(error_body, message)
    Rails.logger.error "Apple Messages Unauthorized: #{error_body}"
    message.update!(
      status: :failed,
      external_error: "Authentication failed: #{error_body}"
    )
  end

  def self.handle_forbidden(error_body, message)
    Rails.logger.error "Apple Messages Forbidden: #{error_body}"
    message.update!(
      status: :failed,
      external_error: "Access denied: #{error_body}"
    )
  end

  def self.handle_rate_limit(error_body, message)
    Rails.logger.warn "Apple Messages Rate Limited: #{error_body}"
    # Retry after delay
    SendReplyJob.set(wait: 60.seconds).perform_later(message.id)
  end

  def self.handle_server_error(error_body, message)
    Rails.logger.error "Apple Messages Server Error: #{error_body}"
    # Retry with exponential backoff
    SendReplyJob.set(wait: 5.minutes).perform_later(message.id)
  end

  def self.handle_unknown_error(error_code, error_body, message)
    Rails.logger.error "Apple Messages Unknown Error #{error_code}: #{error_body}"
    message.update!(
      status: :failed,
      external_error: "Unknown error (#{error_code}): #{error_body}"
    )
  end
end
```

## 6. Testing

### 6.1 Service Tests
```ruby
# spec/services/apple_messages_for_business/send_message_service_spec.rb
require 'rails_helper'

RSpec.describe AppleMessagesForBusiness::SendMessageService do
  let(:channel) { create(:channel_apple_messages_for_business) }
  let(:message) { create(:message, content: 'Test message') }
  let(:destination_id) { 'test_destination_id' }
  let(:service) { described_class.new(channel: channel, destination_id: destination_id, message: message) }

  describe '#perform' do
    context 'when sending text message' do
      before do
        stub_request(:post, "https://mspgw.push.apple.com/v1/message")
          .to_return(status: 200, body: '{"success": true}')
      end

      it 'sends message successfully' do
        result = service.perform
        expect(result[:success]).to be true
        expect(result[:message_id]).to be_present
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, "https://mspgw.push.apple.com/v1/message")
          .to_return(status: 400, body: '{"error": "Bad request"}')
      end

      it 'returns error result' do
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('400')
      end
    end
  end
end
```

This completes the outgoing message services implementation for Apple Messages for Business, providing comprehensive support for text messages, interactive content, and proper error handling.