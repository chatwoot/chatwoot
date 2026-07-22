class SendReplyJob < ApplicationJob
  queue_as :high

  INBOX_DISABLED_ERROR = 'This inbox is currently disabled'.freeze

  CHANNEL_SERVICES = {
    'Channel::TwitterProfile' => ::Twitter::SendOnTwitterService,
    'Channel::TwilioSms' => ::Twilio::SendOnTwilioService,
    'Channel::Line' => ::Line::SendOnLineService,
    'Channel::Telegram' => ::Telegram::SendOnTelegramService,
    'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService,
    'Channel::Sms' => ::Sms::SendOnSmsService,
    'Channel::Instagram' => ::Instagram::SendOnInstagramService,
    'Channel::Tiktok' => ::Tiktok::SendOnTiktokService,
    'Channel::Email' => ::Email::SendOnEmailService,
    'Channel::WebWidget' => ::Messages::SendEmailNotificationService,
    'Channel::Api' => ::Messages::SendEmailNotificationService
  }.freeze

  def perform(message_id)
    message = Message.find(message_id)
    channel_name = message.conversation.inbox.channel.class.to_s
    return handle_disabled_inbox(message, channel_name) unless message.inbox.active?

    return send_on_facebook_page(message) if channel_name == 'Channel::FacebookPage'

    service_class = CHANNEL_SERVICES[channel_name]
    return unless service_class

    service_class.new(message: message).perform
  end

  private

  def handle_disabled_inbox(message, channel_name)
    return unless send_service_available?(channel_name)
    return unless deliverable_reply?(message, channel_name)

    mark_message_failed(message)
  end

  def send_service_available?(channel_name)
    channel_name == 'Channel::FacebookPage' || CHANNEL_SERVICES.key?(channel_name)
  end

  def deliverable_reply?(message, channel_name)
    return false unless deliverable_message?(message)
    return message.email_notifiable_message? if email_channel?(channel_name)
    return email_notification_deliverable?(message, channel_name) if email_notification_channel?(channel_name)

    true
  end

  def deliverable_message?(message)
    return false if message.private?
    return false unless message.outgoing? || message.template?
    return false if message.source_id.present?
    return false if message.content_type == 'voice_call'

    true
  end

  def email_channel?(channel_name)
    channel_name == 'Channel::Email'
  end

  def email_notification_channel?(channel_name)
    %w[Channel::WebWidget Channel::Api].include?(channel_name)
  end

  def email_notification_deliverable?(message, channel_name)
    return false unless message.email_notifiable_message?
    return false if message.conversation.contact.email.blank?
    return false unless message.account.within_email_rate_limit?

    email_notification_enabled?(message.inbox, channel_name)
  end

  def email_notification_enabled?(inbox, channel_name)
    return inbox.channel.continuity_via_email if channel_name == 'Channel::WebWidget'
    return inbox.account.feature_enabled?('email_continuity_on_api_channel') if channel_name == 'Channel::Api'

    false
  end

  def mark_message_failed(message)
    Messages::StatusUpdateService.new(message, 'failed', INBOX_DISABLED_ERROR).perform
  end

  def send_on_facebook_page(message)
    if message.conversation.additional_attributes['type'] == 'instagram_direct_message'
      ::Instagram::Messenger::SendOnInstagramService.new(message: message).perform
    else
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end
