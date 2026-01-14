class SendReplyJob < ApplicationJob
  queue_as :high

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
    inbox = message.conversation.inbox
    channel_name = inbox.channel.class.to_s

    return send_on_facebook_page(message) if channel_name == 'Channel::FacebookPage'
    return send_on_evolution(message) if channel_name == 'Channel::Api' && inbox.evolution_inbox?

    service_class = CHANNEL_SERVICES[channel_name]
    return unless service_class

    service_class.new(message: message).perform
  end

  private

  def send_on_evolution(message)
    ::Evolution::SendOnEvolutionBaileysService.new(message: message).perform
  end

  def send_on_facebook_page(message)
    if message.conversation.additional_attributes['type'] == 'instagram_direct_message'
      ::Instagram::Messenger::SendOnInstagramService.new(message: message).perform
    else
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end
