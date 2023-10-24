class Line::SendOnLineService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Line
  end

  def perform_reply
    response = channel.client.push_message(message.conversation.contact_inbox.source_id, [{ type: 'text', text: nil }])
    parsed_json = JSON.parse(response.body)
    message.update!(status: :failed, external_error: external_error(parsed_json)) unless response.code == '200'
  end

  # https://developers.line.biz/en/reference/messaging-api/#error-responses
  def external_error(error)
    message = error['message']
    details = error['details']

    return message if details.empty?

    detail_messages = details.map do |detail|
      "#{detail['property']}: #{detail['message']}"
    end

    [message, detail_messages].flatten.join(', ')
  end
end
