module Baileys
  class SendOnBaileysService < Base::SendOnChannelService
    private

    def channel_class
      Channel::BaileysWhatsapp
    end

    def perform_reply
      message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
      message.update!(source_id: message_id, status: :sent) if message_id.present?
    end
  end
end
