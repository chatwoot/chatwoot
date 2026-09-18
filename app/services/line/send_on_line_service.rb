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
      Messages::StatusUpdateService.new(message, 'delivered').perform
    else
      # If the request is not successful, update the message status to failed and save the external error
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_json)).perform
    end
  end

  def build_payload
    if flex_container.present?
      build_flex_payload
    elsif message.content_type == 'input_select' && message.content_attributes['items'].any?
      build_input_select_payload
    else
      build_text_payload
    end
  end

  def build_text_payload
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

      # Use file_url (permanent redirect-based URL) instead of download_url (signed URL that expires in 5 minutes).
      # LINE mobile app lazy-loads images and may fetch them well after the message is sent.
      original_url = attachment.file_url
      preview_url = attachment.thumb_url.presence || original_url

      {
        type: attachment.file_type,
        originalContentUrl: original_url,
        previewImageUrl: preview_url
      }
    end
  end

  # https://developers.line.biz/en/reference/messaging-api/#text-message
  def text_message
    {
      type: 'text',
      text: message.outgoing_content
    }
  end

  # A caller (an agent bot, an automation, an integration) may supply a complete
  # LINE Flex container in `content_attributes['line_flex']`, which is sent
  # through untouched. The generated input_select bubble below cannot express a
  # hero image, a URI action, or a carousel, so anything richer than a list of
  # reply buttons is currently unreachable from Chatwoot.
  #
  # Only a bubble or carousel is accepted; anything else falls back to the
  # existing behaviour rather than sending LINE a payload it will reject.
  # https://developers.line.biz/en/reference/messaging-api/#flex-message
  def flex_container
    container = message.content_attributes['line_flex']
    return unless container.is_a?(Hash)
    return unless %w[bubble carousel].include?(container['type'] || container[:type])

    container
  end

  # altText is what LINE shows in the notification and on clients that cannot
  # render Flex, so it must never be blank. LINE caps it at 400 characters.
  def build_flex_payload
    {
      type: 'flex',
      altText: (message.outgoing_content.presence || 'Message')[0, 400],
      contents: flex_container
    }
  end

  # https://developers.line.biz/en/reference/messaging-api/#flex-message
  def build_input_select_payload
    {
      type: 'flex',
      altText: message.content,
      contents: {
        type: 'bubble',
        body: {
          type: 'box',
          layout: 'vertical',
          contents: [
            {
              type: 'text',
              text: message.content,
              wrap: true
            },
            *input_select_to_button
          ]
        }
      }
    }
  end

  def input_select_to_button
    message.content_attributes['items'].map do |item|
      {
        type: 'button',
        style: 'link',
        height: 'sm',
        action: {
          type: 'message',
          label: item['title'],
          text: item['value']
        }
      }
    end
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
