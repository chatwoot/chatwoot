class CommonWhatsapp::SendOnCommonWhatsappService < Base::SendOnChannelService
  private

  def channel_class
    Channel::CommonWhatsapp
  end

  def perform_reply
    send_session_message
  end
  
  def send_session_message
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end

end
