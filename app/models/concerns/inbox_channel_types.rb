# frozen_string_literal: true

module InboxChannelTypes
  extend ActiveSupport::Concern

  def sms?
    channel_type == 'Channel::Sms'
  end

  def facebook?
    channel_type == 'Channel::FacebookPage'
  end

  def instagram?
    (facebook? || instagram_direct?) && channel.instagram_id.present?
  end

  def instagram_direct?
    channel_type == 'Channel::Instagram'
  end

  def web_widget?
    channel_type == 'Channel::WebWidget'
  end

  def api?
    channel_type == 'Channel::Api'
  end

  def email?
    channel_type == 'Channel::Email'
  end

  def twilio?
    channel_type == 'Channel::TwilioSms'
  end

  def twitter?
    channel_type == 'Channel::TwitterProfile'
  end

  def whatsapp?
    channel_type == 'Channel::Whatsapp'
  end

  def inbox_type
    channel.name
  end

  def active_bot?
    agent_bot_inbox&.active? || hooks.where(app_id: %w[dialogflow],
                                            status: 'enabled').count.positive?
  end
end
