class Plivo::SendOnPlivoService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Plivo
  end

  def perform_reply
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end
end
