class Line::SendOnLineService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Line
  end

  def perform_reply
    return Line::NotificationMessageService.new(message: message).perform if notification_message?

    response_body, status_code, _headers = channel.messaging_api_client.push_message_with_http_info(
      push_message_request: Line::Bot::V2::MessagingApi::PushMessageRequest.new(
        to: message.conversation.contact_inbox.source_id,
        messages: Array.wrap(build_payload).compact
      )
    )

    if status_code == 200
      Messages::StatusUpdateService.new(message, 'delivered').perform
    else
      Messages::StatusUpdateService.new(message, 'failed', external_error(response_body)).perform
    end
  end

  def notification_message?
    Line::NotificationMessageService.notification_payload?(template_params)
  end

  def template_params
    message.additional_attributes&.fetch('template_params', {})
  end

  def build_payload
    if message.content_type == 'input_select' && message.content_attributes['items'].any?
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
      original_url = attachment.file_url
      preview_url = attachment.thumb_url.presence || original_url

      case attachment.file_type
      when 'image'
        Line::Bot::V2::MessagingApi::ImageMessage.new(
          original_content_url: original_url,
          preview_image_url: preview_url
        )
      when 'video'
        Line::Bot::V2::MessagingApi::VideoMessage.new(
          original_content_url: original_url,
          preview_image_url: preview_url
        )
      end
    end
  end

  # https://developers.line.biz/en/reference/messaging-api/#text-message
  def text_message
    Line::Bot::V2::MessagingApi::TextMessage.new(
      text: message.outgoing_content
    )
  end

  # https://developers.line.biz/en/reference/messaging-api/#flex-message
  def build_input_select_payload
    Line::Bot::V2::MessagingApi::FlexMessage.new(
      alt_text: message.content,
      contents: Line::Bot::V2::MessagingApi::FlexBubble.new(
        body: Line::Bot::V2::MessagingApi::FlexBox.new(
          layout: 'vertical',
          contents: [
            Line::Bot::V2::MessagingApi::FlexText.new(
              text: message.content,
              wrap: true
            ),
            *input_select_to_button
          ]
        )
      )
    )
  end

  def input_select_to_button
    message.content_attributes['items'].map do |item|
      Line::Bot::V2::MessagingApi::FlexButton.new(
        style: 'link',
        height: 'sm',
        action: Line::Bot::V2::MessagingApi::MessageAction.new(
          label: item['title'],
          text: item['value']
        )
      )
    end
  end

  # https://developers.line.biz/en/reference/messaging-api/#error-responses
  def external_error(error)
    case error
    when Line::Bot::V2::MessagingApi::ErrorResponse
      format_external_error(error.message, error.details)
    when String
      parsed = begin
        JSON.parse(error)
      rescue JSON::ParserError
        nil
      end

      return error unless parsed.is_a?(Hash)

      format_external_error(parsed['message'], parsed['details'])
    else
      message = error.respond_to?(:message) ? error.message : error.to_s
      details = error.respond_to?(:details) ? error.details : nil
      format_external_error(message, details)
    end
  end

  def format_external_error(message, details)
    return message if details.blank?

    detail_messages = details.map do |detail|
      property = detail.respond_to?(:property) ? detail.property : detail['property']
      detail_message = detail.respond_to?(:message) ? detail.message : detail['message']
      "#{property}: #{detail_message}"
    end

    [message, detail_messages].join(', ')
  end
end
