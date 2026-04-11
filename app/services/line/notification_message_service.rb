class Line::NotificationMessageService
  pattr_initialize [:message!]

  SUCCESS_STATUS_CODES = [200, 202].freeze
  NOTIFICATION_TYPES = %w[template flexible].freeze
  DELIVERY_TAG_PREFIX = 'chatwoot-line-pnp-'.freeze

  def self.notification_payload?(template_params)
    Line::NotificationMessagePayload.valid?(template_params)
  end

  def perform
    return fail_with_error('LINE notification messages do not support attachments') if message.attachments.any?
    return fail_with_error('LINE notification messages require a valid type') unless notification_type.in?(NOTIFICATION_TYPES)
    return fail_with_error('LINE notification messages require a phone number') if resolved_phone_number.blank?
    return fail_with_error(line_payload_error_message) if payload_specific_data.blank?

    persist_notification_context!
    response_body, status_code, headers = send_notification_message

    if success_status?(status_code)
      persist_request_id!(headers['x-line-request-id'])
    else
      fail_with_error(external_error(response_body))
    end
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :inbox, to: :conversation

  def payload_specific_data
    case notification_type
    when 'template'
      template_params['template_key']
    when 'flexible'
      template_params['messages']
    end
  end

  def line_payload_error_message
    case notification_type
    when 'template'
      'LINE notification template messages require template_key'
    when 'flexible'
      'LINE notification flexible messages require messages'
    else
      'LINE notification messages require a valid type'
    end
  end

  def notification_type
    template_params['type']
  end

  def template_params
    @template_params ||= Line::NotificationMessagePayload.normalize(message.additional_attributes&.fetch('template_params', {}))
  end

  def resolved_phone_number
    @resolved_phone_number ||= normalize_phone_number(explicit_phone_number || contact.phone_number)
  end

  def explicit_phone_number
    template_params['phone_number']
  end

  def normalize_phone_number(phone_number)
    return if phone_number.blank?
    return unless TelephoneNumber.valid?(phone_number)

    TelephoneNumber.parse(phone_number).e164_number
  end

  def hashed_phone_number
    @hashed_phone_number ||= Digest::SHA256.hexdigest(resolved_phone_number)
  end

  def delivery_tag
    "#{DELIVERY_TAG_PREFIX}#{message.id}"
  end

  def persist_notification_context!
    message.update!(
      additional_attributes: message.additional_attributes.to_h.merge(
        'template_params' => template_params.merge(
          'phone_number' => resolved_phone_number,
          'phone_number_sha256' => hashed_phone_number,
          'delivery_tag' => delivery_tag
        )
      )
    )
  end

  def persist_request_id!(request_id)
    return if request_id.blank?

    message.update!(
      source_id: request_id,
      additional_attributes: message.additional_attributes.to_h.merge(
        'template_params' => template_params.merge(
          'phone_number' => resolved_phone_number,
          'phone_number_sha256' => hashed_phone_number,
          'delivery_tag' => delivery_tag,
          'x_line_request_id' => request_id
        )
      )
    )
  end

  def send_notification_message
    case notification_type
    when 'template'
      send_templated_notification_message
    when 'flexible'
      send_flexible_notification_message
    end
  end

  def send_templated_notification_message
    response = channel.notification_message_http_client.post(
      path: '/v2/bot/message/pnp/templated/push',
      body_params: template_request_body,
      headers: { 'X-Line-Delivery-Tag' => delivery_tag }
    )

    [response.body, response.code.to_i, response.each_header.to_h]
  end

  def template_request_body
    body = {
      to: hashed_phone_number,
      template_key: template_params['template_key']
    }
    body[:body] = template_params['body'] if template_params['body'].present?
    body[:notification_disabled] = template_params['notification_disabled'] unless template_params['notification_disabled'].nil?
    body
  end

  def send_flexible_notification_message
    channel.messaging_api_client.push_messages_by_phone_with_http_info(
      pnp_messages_request: Line::Bot::V2::MessagingApi::PnpMessagesRequest.new(
        to: hashed_phone_number,
        messages: template_params['messages'],
        notification_disabled: template_params.fetch('notification_disabled', false)
      ),
      x_line_delivery_tag: delivery_tag
    )
  end

  def channel
    @channel ||= inbox.channel
  end

  def success_status?(status_code)
    SUCCESS_STATUS_CODES.include?(status_code)
  end

  def fail_with_error(error_message)
    Messages::StatusUpdateService.new(message, 'failed', error_message).perform
  end

  def external_error(response_body)
    case response_body
    when Line::Bot::V2::MessagingApi::ErrorResponse
      format_external_error(response_body.message, response_body.details)
    when String
      parsed = begin
        JSON.parse(response_body)
      rescue JSON::ParserError
        nil
      end

      return response_body unless parsed.is_a?(Hash)

      format_external_error(parsed['message'], parsed['details'])
    else
      message = response_body.respond_to?(:message) ? response_body.message : response_body.to_s
      details = response_body.respond_to?(:details) ? response_body.details : nil
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
