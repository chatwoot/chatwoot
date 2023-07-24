class Sms::SendOnSmsService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Sms
  end

  def perform_reply
    send_on_sms
  end

  def send_on_sms
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end
end
