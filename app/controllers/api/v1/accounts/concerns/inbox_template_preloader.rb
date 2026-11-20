# frozen_string_literal: true

module Api::V1::Accounts::Concerns::InboxTemplatePreloader
  extend ActiveSupport::Concern

  private

  def preload_channel_templates(items)
    channels = extract_channels(items)
    preload_whatsapp_templates(channels)
    preload_twilio_templates(channels)
  end

  def extract_channels(items)
    Array(items).filter_map do |item|
      case item
      when Channel::Whatsapp, Channel::TwilioSms then item
      when Inbox then item.channel
      else item.try(:channel) || item.try(:inbox)&.channel
      end
    end
  end

  def preload_whatsapp_templates(channels)
    whatsapp_channels = channels.grep(Channel::Whatsapp).reject { |c| c.has_attribute?(:message_templates) }
    return if whatsapp_channels.blank?

    templates = Channel::Whatsapp.unscoped.where(id: whatsapp_channels.map(&:id)).pluck(:id, :message_templates).to_h
    whatsapp_channels.each { |c| c[:message_templates] = templates[c.id] }
  end

  def preload_twilio_templates(channels)
    twilio_channels = channels.grep(Channel::TwilioSms).reject { |c| c.has_attribute?(:content_templates) }
    return if twilio_channels.blank?

    templates = Channel::TwilioSms.unscoped.where(id: twilio_channels.map(&:id)).pluck(:id, :content_templates).to_h
    twilio_channels.each { |c| c[:content_templates] = templates[c.id] }
  end
end
