# frozen_string_literal: true

module Api::V1::Accounts::Concerns::InboxTemplatePreloader
  extend ActiveSupport::Concern

  private

  def preload_channel_templates(inboxes)
    preload_whatsapp_templates(inboxes)
    preload_twilio_templates(inboxes)
  end

  def preload_whatsapp_templates(inboxes)
    channels = inboxes.map(&:channel).grep(Channel::Whatsapp).reject { |c| c.has_attribute?(:message_templates) }
    return if channels.blank?

    templates = Channel::Whatsapp.unscoped.where(id: channels.map(&:id)).pluck(:id, :message_templates).to_h
    channels.each { |c| c[:message_templates] = templates[c.id] }
  end

  def preload_twilio_templates(inboxes)
    channels = inboxes.map(&:channel).grep(Channel::TwilioSms).reject { |c| c.has_attribute?(:content_templates) }
    return if channels.blank?

    templates = Channel::TwilioSms.unscoped.where(id: channels.map(&:id)).pluck(:id, :content_templates).to_h
    channels.each { |c| c[:content_templates] = templates[c.id] }
  end
end
