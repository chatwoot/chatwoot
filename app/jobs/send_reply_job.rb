class SendReplyJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    channel_name = conversation.inbox.channel.class.to_s

    services = {
      'Channel::TwitterProfile' => ::Twitter::SendOnTwitterService,
      'Channel::TwilioSms' => ::Twilio::SendOnTwilioService,
      'Channel::Line' => ::Line::SendOnLineService,
      'Channel::Telegram' => ::Telegram::SendOnTelegramService,
      'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService,
      'Channel::Sms' => ::Sms::SendOnSmsService,
      'Channel::Shopee' => ::Shopee::SendOnShopService,
      'Channel::Zalo' => ::Zalo::SendOnAccountService,
      'Channel::FacebookPage' => ::Facebook::SendOnInboxService,
      'Channel::Instagram' => ::Instagram::SendOnInstagramService
    }

    send_service = services[channel_name]
    send_service.new(message: message).perform if send_service.present?
  end
end
