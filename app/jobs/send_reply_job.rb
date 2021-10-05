class SendReplyJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    channel_name = conversation.inbox.channel.class.to_s

    case channel_name
    when 'Channel::FacebookPage'
      send_on_facebook_page(message)
    when 'Channel::TwitterProfile'
      ::Twitter::SendOnTwitterService.new(message: message).perform
    when 'Channel::TwilioSms'
      ::Twilio::SendOnTwilioService.new(message: message).perform
    when 'Channel::Line'
      ::Line::SendOnLineService.new(message: message).perform
    when 'Channel::Telegram'
      ::Telegram::SendOnTelegramService.new(message: message).perform
    when 'Channel::Whatsapp'
      ::Whatsapp::SendOnWhatsappService.new(message: message).perform
    end
  end

  private

  def send_on_facebook_page(message)
    if message.conversation.additional_attributes['type'] == 'instagram_direct_message'
      ::Instagram::SendOnInstagramService.new(message: message).perform
    else
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end
