# frozen_string_literal: true

module Aloo::TypingIndicatable
  extend ActiveSupport::Concern

  private

  def dispatch_typing(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: @assistant, is_private: false)
  end

  # Dispatcher: sends channel-native typing indicator based on inbox type
  def send_channel_typing_indicator
    case @conversation.inbox.channel_type
    when 'Channel::Whatsapp'
      send_whatsapp_typing_indicator
    when 'Channel::Instagram'
      send_instagram_typing_indicator
    when 'Channel::Telegram'
      send_telegram_typing_indicator
    end
  end

  def send_whatsapp_typing_indicator
    channel = @conversation.inbox.channel
    return unless channel.provider == 'whatsapp_cloud'

    phone_number = @conversation.contact_inbox.source_id
    return if phone_number.blank?

    Rails.logger.info "[#{self.class.name}] Sending WhatsApp typing indicator to #{phone_number}"
    service = Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
    service.send_typing_indicator(phone_number, message_id: @message&.source_id)
  rescue StandardError => e
    Rails.logger.error "[#{self.class.name}] Failed to send WhatsApp typing indicator: #{e.message}"
  end

  def send_instagram_typing_indicator
    channel = @conversation.inbox.channel
    recipient_id = @conversation.contact_inbox.source_id
    return if recipient_id.blank?

    Rails.logger.info "[#{self.class.name}] Sending Instagram typing indicator to #{recipient_id}"
    instagram_id = channel.instagram_id.presence || 'me'
    HTTParty.post(
      "https://graph.instagram.com/v22.0/#{instagram_id}/messages",
      body: { recipient: { id: recipient_id }, sender_action: 'typing_on' }.to_json,
      headers: { 'Content-Type' => 'application/json' },
      query: { access_token: channel.access_token }
    )
  rescue StandardError => e
    Rails.logger.error "[#{self.class.name}] Failed to send Instagram typing indicator: #{e.message}"
  end

  def send_telegram_typing_indicator
    channel = @conversation.inbox.channel
    chat_id = @conversation.additional_attributes['chat_id']
    return if chat_id.blank?

    Rails.logger.info "[#{self.class.name}] Sending Telegram typing indicator to chat #{chat_id}"
    body = { chat_id: chat_id, action: 'typing' }
    biz_id = @conversation.additional_attributes['business_connection_id']
    body[:business_connection_id] = biz_id if biz_id.present?

    HTTParty.post(
      "#{channel.telegram_api_url}/sendChatAction",
      body: body,
      headers: Channel::Telegram::TELEGRAM_HEADERS
    )
  rescue StandardError => e
    Rails.logger.error "[#{self.class.name}] Failed to send Telegram typing indicator: #{e.message}"
  end
end
