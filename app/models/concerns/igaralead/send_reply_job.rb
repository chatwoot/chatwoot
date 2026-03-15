# frozen_string_literal: true

module Igaralead::SendReplyJob
  BAILEYS_CHANNEL_SERVICES = {
    'Channel::BaileysWhatsapp' => ::Baileys::SendOnBaileysService
  }.freeze

  def perform(message_id)
    message = Message.find(message_id)
    channel_name = message.conversation.inbox.channel.class.to_s

    baileys_service = BAILEYS_CHANNEL_SERVICES[channel_name]
    if baileys_service
      baileys_service.new(message: message).perform
    else
      super
    end
  end
end
