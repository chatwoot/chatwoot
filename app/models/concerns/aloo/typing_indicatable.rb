# frozen_string_literal: true

module Aloo::TypingIndicatable
  extend ActiveSupport::Concern

  private

  def dispatch_typing(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: @assistant, is_private: false)
  end

  def send_whatsapp_typing_indicator
    inbox = @conversation.inbox
    return unless inbox.channel_type == 'Channel::Whatsapp'

    channel = inbox.channel
    return unless channel.provider == 'whatsapp_cloud'

    phone_number = @conversation.contact_inbox.source_id
    return if phone_number.blank?

    Rails.logger.info "[#{self.class.name}] Sending WhatsApp typing indicator to #{phone_number}"
    Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel).send_typing_indicator(phone_number)
  rescue StandardError => e
    Rails.logger.error "[#{self.class.name}] Failed to send WhatsApp typing indicator: #{e.message}"
  end
end
