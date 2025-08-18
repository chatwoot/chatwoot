class Whatsapp::Providers::WhapiService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    # Since WHAPI has no template API, send template content as regular message
    template_message = create_template_message(template_info)
    send_message(phone_number, template_message)
  end

  def sync_templates
    # No-op since WHAPI doesn't use templates
    whatsapp_channel.mark_message_templates_updated
    true
  end

  def validate_provider_config?
    # For Whapi partner channels in pending status, we don't require health check
    # since the WhatsApp connection is established after QR code scanning
    if whatsapp_channel.whapi_partner_channel? && whatsapp_channel.whapi_connection_status == 'pending'
      # Validate that we have the required token from partner API
      return whatsapp_channel.provider_config['api_key'].present? || 
             whatsapp_channel.provider_config['whapi_channel_token'].present?
    end

    # For regular Whapi channels or connected partner channels, perform health check
    response = HTTParty.get("#{api_base_path}/health", headers: api_headers)
    response.success?
  rescue Net::ReadTimeout, Net::OpenTimeout, SocketError => e
    Rails.logger.error "WHAPI health check failed: #{e.message}"
    false
  end

  def error_message(response)
    # Enhanced error parsing for WHAPI
    parsed_response = response.parsed_response
    if parsed_response.is_a?(Hash)
      # Look for a specific error message from WHAPI first
      error_msg = parsed_response.dig('error', 'message') || parsed_response['message']
      return error_msg if error_msg.present?
    end
    # Only return fallback error message if response indicates actual failure
    return nil if parsed_response.is_a?(Hash) && parsed_response.empty?

    # If no specific error, return a clear failure message
    "WHAPI API request failed with status #{response.code}. Response: #{response.body}"
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def media_url(_media_id)
    # Not needed for WHAPI - media URLs are direct
    nil
  end

  def process_response(response)
    Rails.logger.info '=== WHAPI RESPONSE PROCESSING START ==='
    Rails.logger.info "Response status: #{response.code}"
    Rails.logger.info "Response content-type: #{response.headers['content-type']}"
    Rails.logger.info "Response body: #{response.body}"

    begin
      parsed_response = response.parsed_response
      Rails.logger.info "Parsed response class: #{parsed_response.class}"
      Rails.logger.info "Parsed response content: #{parsed_response.inspect}"
    rescue StandardError => e
      Rails.logger.error "Failed to parse response: #{e.message}"
      parsed_response = nil
    end

    # Check for successful status codes (200-299) and presence of message ID
    # WHAPI returns the ID in response.message.id, not at the top level
    if (200..299).cover?(response.code)
      Rails.logger.info '✓ HTTP status code indicates success'

      if parsed_response.is_a?(Hash)
        Rails.logger.info '✓ Response is a valid hash'
        message_id = parsed_response.dig('message', 'id')
        Rails.logger.info "Message ID from response: #{message_id}"

        if message_id.present?
          Rails.logger.info "✓ WHAPI Message sent successfully with ID: #{message_id}"
          Rails.logger.info '=== WHAPI RESPONSE PROCESSING END (SUCCESS) ==='
          return message_id
        else
          Rails.logger.warn '⚠ No message ID found in successful response'
        end
      else
        Rails.logger.warn "⚠ Response is not a hash: #{parsed_response.class}"
      end
    else
      Rails.logger.error "✗ HTTP status code indicates failure: #{response.code}"
    end

    # If we get here, something went wrong
    Rails.logger.error '=== WHAPI ERROR DETAILS ==='
    Rails.logger.error "Status: #{response.code}"
    Rails.logger.error "Raw body: #{response.body}"
    Rails.logger.error "Parsed response: #{parsed_response.inspect}"

    if parsed_response.is_a?(Hash)
      error_message = parsed_response.dig('error', 'message') ||
                      parsed_response['message'] ||
                      parsed_response['error'] ||
                      'Unknown error'
      Rails.logger.error "Extracted error message: #{error_message}"
    end

    Rails.logger.info '=== WHAPI RESPONSE PROCESSING END (ERROR) ==='
    handle_error(response)
    nil
  end

  def mark_as_read(message)
    response = HTTParty.put(
      "#{api_base_path}/messages/#{message.source_id}",
      headers: api_headers
    )

    # Log for debugging
    Rails.logger.info "WHAPI Mark as Read Response: Status=#{response.code}, Body=#{response.body}"

    if response.success?
      Rails.logger.info "WHAPI Message marked as read successfully: #{message.source_id}"
    else
      Rails.logger.error "WHAPI Error marking message as read: Status=#{response.code}, Response=#{response.body}"
    end

    response
  end

  def fetch_contact_info(phone_number)
    return nil unless phone_number.present?

    begin
      # Clean phone number - remove any WhatsApp suffixes and ensure it's just digits
      clean_phone = phone_number.to_s.gsub(/[@c\.us|whatpne].*$/, '').gsub(/\D/, '')

      Rails.logger.info "Fetching contact info for #{clean_phone}"

      # Use only the profile endpoint which contains all the information we need
      profile_response = HTTParty.get(
        "#{api_base_path}/contacts/#{clean_phone}/profile",
        headers: api_headers,
        timeout: 10
      )

      return nil unless profile_response.success?

      profile_data = profile_response.parsed_response

      Rails.logger.info "WHAPI Contact Debug: Profile response: #{profile_data}"

      # Return structured contact information from profile endpoint
      result = {
        avatar_url: profile_data['icon_full'] || profile_data['icon'],
        name: profile_data['pushname'] || profile_data['name'],
        status: profile_data['about'],
        business_name: profile_data['business_name'],
        raw_profile_response: profile_data
      }

      Rails.logger.info "WHAPI Contact Debug: Final result: #{result}"

      # Return nil if we couldn't get any useful information
      if result[:avatar_url].blank? && result[:name].blank?
        Rails.logger.warn "WHAPI contact fetch: No useful data found for #{phone_number}"
        return nil
      end

      result
    rescue Net::ReadTimeout, Net::OpenTimeout, SocketError => e
      Rails.logger.warn "WHAPI contact fetch timeout for #{phone_number}: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "WHAPI contact fetch error for #{phone_number}: #{e.message}"
      nil
    end
  end

  private

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/messages/text",
      headers: api_headers,
      body: {
        to: phone_number,
        body: message.outgoing_content
      }.merge(whapi_reply_context(message)).to_json
    )
    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    whapi_type = map_chatwoot_to_whapi_type(attachment)

    endpoint = "#{api_base_path}/messages/media/#{whapi_type}"
    Rails.logger.info "WHAPI sending to dynamic endpoint: #{endpoint}"

    # Build query parameters as required by Whapi
    query_params = build_whapi_send_params(phone_number, message, attachment, whapi_type)

    # Download the file content for the request body
    file_content = download_attachment_content(attachment)
    content_type = get_whapi_content_type(attachment, whapi_type)

    Rails.logger.info "WHAPI query params: #{query_params}"
    Rails.logger.info "WHAPI content type: #{content_type}"
    Rails.logger.info "WHAPI file size: #{file_content.size} bytes"

    response = HTTParty.post(
      endpoint,
      query: query_params,
      headers: {
        'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}",
        'Content-Type' => content_type
      },
      body: file_content
    )
    process_response(response)
  end

  def map_chatwoot_to_whapi_type(attachment)
    case attachment.file_type
    when 'image' then 'image'
    when 'audio' then determine_audio_type(attachment)
    when 'video' then 'video'
    when 'file' then 'document'
    else 'document'
    end
  end

  def determine_audio_type(attachment)
    # This logic seems fine from your current file.
    # It correctly identifies voice messages vs. regular audio.
    is_voice = attachment.file.content_type.include?('ogg')
    is_voice ? 'voice' : 'audio'
  end

  def build_whapi_send_params(phone_number, message, attachment, whapi_type)
    params = {
      to: phone_number
    }

    # Add caption for supported types (not for voice messages)
    params[:caption] = message.content if whapi_type != 'voice' && message.content.present?

    # Add filename for documents
    params[:filename] = attachment.file.filename.to_s if whapi_type == 'document' && attachment.file.attached?

    # Add reply context if available
    reply_context = whapi_reply_context(message)
    params.merge!(reply_context) if reply_context.any?

    params
  end

  def download_attachment_content(attachment)
    if attachment.file.content_type&.include?('audio/')
      # For audio, we might need conversion - get the converted file URL and download it
      converted_url = Whatsapp::AudioConversionService.convert_to_whatsapp_format(attachment)

      # If it's a local URL, read the file directly
      if converted_url.include?('rails/active_storage')
        # Download from Rails blob
        attachment.file.download
      else
        # Download from external URL
        HTTParty.get(converted_url).body
      end
    else
      # For other file types, download directly
      attachment.file.download
    end
  end

  def get_whapi_content_type(attachment, whapi_type)
    original_content_type = attachment.file.content_type

    case whapi_type
    when 'voice', 'audio'
      # For audio files, ensure we use the basic audio/ogg format that Whapi supports
      if original_content_type&.start_with?('audio/ogg')
        'audio/ogg'
      elsif original_content_type&.include?('audio/')
        # For other audio types that get converted, use audio/ogg
        'audio/ogg'
      else
        original_content_type || 'audio/ogg'
      end
    else
      # For non-audio files, use the original content type
      original_content_type || 'application/octet-stream'
    end
  end

  def whapi_reply_context(message)
    return {} unless message.content_attributes&.[](:in_reply_to_external_id)

    { quoted: message.content_attributes[:in_reply_to_external_id] }
  end

  def create_template_message(template_info)
    # Convert template info to a message-like object for regular sending
    OpenStruct.new(
      outgoing_content: template_info[:body] || template_info[:text],
      content_attributes: {},
      attachments: []
    )
  end

  def api_base_path
    'https://gate.whapi.cloud'
  end
end