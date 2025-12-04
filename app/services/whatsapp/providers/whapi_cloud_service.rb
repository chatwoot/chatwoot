# frozen_string_literal: true

class Whatsapp::Providers::WhapiCloudService < Whatsapp::Providers::BaseService
  class_attribute :use_admin_token, default: false

  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    elsif should_send_location?(message)
      send_location_message(phone_number, message)
    elsif should_send_link_preview?(message)
      send_link_preview_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(_phone_number, _template_info, _message)
    raise NotImplementedError, 'WhatsApp Light does not support template messages'
  end

  def sync_templates
    # WhatsApp Light does not support templates
    true
  end

  def validate_provider_config?
    return false if whatsapp_channel.provider_config['channel_id'].blank?
    return false if auth_token.blank?

    # Validate with Whapi health endpoint
    response = HTTParty.get(
      "#{api_base_url}/health",
      headers: api_headers
    )

    response.success?
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP LIGHT] Validation failed: #{e.message}"
    false
  end

  def api_headers
    {
      'Authorization' => "Bearer #{auth_token}",
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  def media_url(media_id)
    "#{api_base_url}/media/#{media_id}"
  end

  def api_base_url
    url = whatsapp_channel.provider_config['api_url'] || ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')
    url.chomp('/')
  end

  def error_message(response)
    parsed = response.parsed_response
    return nil if parsed.blank?

    # Whapi error format: { "message": "error description" } or { "error": "error description" }
    error_msg = parsed['message'] || parsed['error']

    # If error_msg is still an object/hash, convert it to string
    return error_msg if error_msg.is_a?(String)

    # If the whole response is an error object, try to extract a meaningful message
    return parsed.to_json if parsed.is_a?(Hash)

    nil
  end

  private

  def auth_token
    if self.class.use_admin_token
      ENV.fetch('WHAPI_ADMIN_CHANNEL_TOKEN', nil)
    else
      whatsapp_channel.provider_config['token']
    end
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_url}/messages/text",
      headers: api_headers,
      body: {
        to: format_phone_number(phone_number),
        body: message.outgoing_content
      }.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = map_attachment_type(attachment.file_type)

    body = {
      to: format_phone_number(phone_number),
      media: attachment.download_url
    }

    # Add caption for supported types (not for audio/voice)
    body[:caption] = message.outgoing_content if message.outgoing_content.present? && !%w[audio voice].include?(type)

    # Add filename for documents
    body[:filename] = attachment.file.filename.to_s if type == 'document' && attachment.file.attached?

    response = HTTParty.post(
      "#{api_base_url}/messages/#{type}",
      headers: api_headers,
      body: body.to_json
    )

    process_response(response, message)
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{api_base_url}/messages/interactive",
      headers: api_headers,
      body: {
        to: format_phone_number(phone_number),
        interactive: payload
      }.to_json
    )

    process_response(response, message)
  end

  def send_link_preview_message(phone_number, message)
    link_preview_data = message.content_attributes['link_preview']

    body = {
      to: format_phone_number(phone_number),
      body: message.outgoing_content
    }

    # Add optional fields if present
    body[:title] = link_preview_data['title'] if link_preview_data['title'].present?
    if link_preview_data['media'].present? || link_preview_data['image'].present?
      body[:media] =
        link_preview_data['media'] || link_preview_data['image']
    end

    response = HTTParty.post(
      "#{api_base_url}/messages/link_preview",
      headers: api_headers,
      body: body.to_json
    )

    process_response(response, message)
  end

  def send_location_message(phone_number, message)
    location_data = message.content_attributes

    body = {
      to: format_phone_number(phone_number),
      latitude: location_data['latitude'].to_f,
      longitude: location_data['longitude'].to_f
    }

    # Add optional fields if present
    body[:name] = location_data['name'] if location_data['name'].present?
    body[:address] = location_data['address'] if location_data['address'].present?
    body[:url] = location_data['url'] if location_data['url'].present?

    response = HTTParty.post(
      "#{api_base_url}/messages/location",
      headers: api_headers,
      body: body.to_json
    )

    process_response(response, message)
  end

  def should_send_location?(message)
    message.content_attributes.present? &&
      message.content_attributes['latitude'].present? &&
      message.content_attributes['longitude'].present?
  end

  def should_send_link_preview?(message)
    message.content_attributes.present? &&
      message.content_attributes['link_preview'].present? &&
      message.content_attributes['link_preview']['enabled'] == true
  end

  def format_phone_number(phone_number)
    # Whapi expects phone numbers without + prefix and without @s.whatsapp.net suffix for sending
    phone_number.gsub(/^\+/, '').gsub(/@s\.whatsapp\.net$/, '')
  end

  def map_attachment_type(file_type)
    case file_type
    when 'image' then 'image'
    when 'audio' then 'audio'
    when 'voice' then 'voice'
    when 'video' then 'video'
    else 'document'
    end
  end

  def process_response(response, message)
    parsed_response = response.parsed_response

    Rails.logger.info "[WHATSAPP LIGHT] Send message response - Status: #{response.code}, Body: #{parsed_response.inspect}"

    # Whapi returns 200 with structure: { "sent": true, "message": { "id": "...", ... } }
    if response.success? && parsed_response.is_a?(Hash)
      # Extract message ID from the nested structure
      message_id = parsed_response.dig('message', 'id') || parsed_response['id']

      if message_id.present?
        Rails.logger.info "[WHATSAPP LIGHT] Message sent successfully with ID: #{message_id}"

        # Don't treat pending status as an error - it's normal for Whapi
        # Status will be updated via webhooks (pending -> sent -> delivered -> read)
        return message_id
      end
    end

    # If we get here, something went wrong
    Rails.logger.error "[WHATSAPP LIGHT] Message send failed - Response: #{response.code}, Body: #{parsed_response.inspect}"
    handle_error(response, message)
    nil
  end
end
