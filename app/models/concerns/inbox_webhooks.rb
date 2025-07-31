# frozen_string_literal: true

module InboxWebhooks
  extend ActiveSupport::Concern

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def callback_webhook_url
    case channel_type
    when 'Channel::TwilioSms'
      "#{ENV.fetch('FRONTEND_URL', nil)}/twilio/callback"
    when 'Channel::Sms'
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/sms/#{channel.phone_number.delete_prefix('+')}"
    when 'Channel::Line'
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/line/#{channel.line_channel_id}"
    when 'Channel::Whatsapp'
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{channel.phone_number}"
    end
  end
end
