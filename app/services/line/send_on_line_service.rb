class Line::SendOnLineService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Line
  end

  def perform_reply
    response = channel.client.push_message(message.conversation.contact_inbox.source_id, build_payload)

    return if response.blank?

    parsed_json = JSON.parse(response.body)

    if response.code == '200'
      # If the request is successful, update the message status to delivered
      message.update!(status: :delivered)
    else
      # If the request is not successful, update the message status to failed and save the external error
      message.update!(status: :failed, external_error: external_error(parsed_json))
    end
  end

  def build_payload
    if message.content && message.attachments.any?
      [text_message, *attachments]
    elsif message.content.nil? && message.attachments.any?
      attachments
    else
      text_message
    end
  end

  def attachments
    message.attachments.map do |attachment|
      # Support only image and video for now, https://developers.line.biz/en/reference/messaging-api/#image-message
      next unless attachment.file_type == 'image' || attachment.file_type == 'video'

      {
        type: attachment.file_type,
        originalContentUrl: attachment.download_url,
        previewImageUrl: attachment.download_url
      }
    end
  end

  # https://developers.line.biz/en/reference/messaging-api/#text-message
  def text_message
    {
      type: 'text',
      text: message.content
    }
  end

  # https://developers.line.biz/en/reference/messaging-api/#error-responses
  def external_error(error)
    # Message containing information about the error. See https://developers.line.biz/en/reference/messaging-api/#error-messages
    message = error['message']
    # An array of error details. If the array is empty, this property will not be included in the response.
    details = error['details']

    return message if details.blank?

    detail_messages = details.map { |detail| "#{detail['property']}: #{detail['message']}" }
    [message, detail_messages].join(', ')
  end
end
