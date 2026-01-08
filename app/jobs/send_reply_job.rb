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
    channel_name = message.conversation.inbox.channel.class.to_s

    # Special handling for FacebookPage (needs to check conversation type)
    if channel_name == 'Channel::FacebookPage'
      send_on_facebook_page(message)
      return
    end

    service_class = CHANNEL_SERVICES[channel_name]
    return unless service_class

    service_class.new(message: message).perform
  end

  private

  def send_on_facebook_page(message)
    conversation_type = message.conversation.additional_attributes['type']
    
    if conversation_type == 'instagram_dm' || conversation_type == 'instagram_comments'
      ::Instagram::SendOnInstagramService.new(message: message).perform
    elsif conversation_type == 'feed_comments' || conversation_type == 'facebook_comments'
      ::FacebookComments::SendOnFacebookCommentsService.new(message: message).perform
    else
      # Regular Facebook Messenger messages
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end