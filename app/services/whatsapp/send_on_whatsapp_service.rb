class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    channel.send_message(message.conversation.contact_inbox.source_id, message.content)
  end
end
