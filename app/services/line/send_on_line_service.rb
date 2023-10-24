class Line::SendOnLineService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Line
  end

  def perform_reply
    response = channel.client.push_message(message.conversation.contact_inbox.source_id, [{ type: 'text', text: message.content }])
    message.update!(status: :failed, external_error: "#{response.code} - #{response.message}") unless response.code == 200
  end
end
