class Whatsapp::Providers::WhapiService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
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
    provider_config_object.validate_config?
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
    "WHAPI API request failed with status #{response.code}"
  end

  def api_headers
    api_key = provider_config_object.api_key
    { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
  end

  def media_url(_media_id)
    # Not needed for WHAPI - media URLs are direct
    nil
  end

  def process_response(response, message = nil)
    # Only log details in development
    if Rails.env.development?
      Rails.logger.debug "WHAPI Response: #{response.code} - #{response.headers['content-type']}"
    end

    begin
      parsed_response = response.parsed_response
    rescue JSON::ParserError => e
      Rails.logger.error "WHAPI JSON parsing failed: #{e.message}"
      parsed_response = nil
    rescue StandardError => e
      Rails.logger.error "WHAPI response processing error: #{e.class} - #{e.message}"
      raise e
    end

    # Check for successful status codes and message ID
    if (200..299).cover?(response.code)
      if parsed_response.is_a?(Hash)
        message_id = parsed_response.dig('message', 'id')
        
        if message_id.present?
          Rails.logger.info "WHAPI Message sent successfully with ID: #{message_id}"
          return message_id
        else
          Rails.logger.warn "WHAPI No message ID found in successful response"
        end
      else
        Rails.logger.warn "WHAPI Response is not a hash: #{parsed_response.class}"
      end
    else
      Rails.logger.error "WHAPI HTTP status indicates failure: #{response.code}"
    end

    # Handle error case
    handle_error(response, message)
    nil
  end

  def mark_as_read(message)
    safe_http_request('whapi_mark_read') do
      HTTParty.put(
        "#{api_base_path}/messages/#{message.source_id}",
        headers: api_headers
      )
    end
  rescue StandardError => e
    Rails.logger.error "WHAPI Error marking message as read: #{e.message}"
  end

  def fetch_contact_info(phone_number)
    return nil unless phone_number.present?

    begin
      clean_phone = phone_number.to_s.gsub(/[@c\.us|whatpne].*$/, '').gsub(/\D/, '')
      
      Rails.logger.debug "WHAPI Fetching contact info" if Rails.env.development?

      profile_response = safe_http_request('whapi_fetch_contact') do
        HTTParty.get(
          "#{api_base_path}/contacts/#{clean_phone}/profile",
          headers: api_headers,
          timeout: 10
        )
      end

      return nil unless profile_response.success?

      profile_data = profile_response.parsed_response
      
      result = {
        avatar_url: profile_data['icon_full'] || profile_data['icon'],
        name: profile_data['pushname'] || profile_data['name'],
        status: profile_data['about'],
        business_name: profile_data['business_name']
      }

      if result[:avatar_url].blank? && result[:name].blank?
        Rails.logger.debug "WHAPI No useful contact data found" if Rails.env.development?
        return nil
      end

      result
      
    rescue StandardError => e
      Rails.logger.error "WHAPI contact fetch error: #{e.message}"
      WhapiErrorTracker.track_and_degrade('contact_fetch', e, { phone_number: phone_number })
      nil
    end
  end

  private

  def send_text_message(phone_number, message)
    response = safe_http_request('whapi_send_message') do
      HTTParty.post(
        "#{api_base_path}/messages/text",
        headers: api_headers,
        body: {
          to: phone_number,
          body: message.outgoing_content
        }.merge(whapi_reply_context(message)).to_json
      )
    end
    
    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    whapi_type = map_chatwoot_to_whapi_type(attachment)

    endpoint = "#{api_base_path}/messages/media/#{whapi_type}"
    
    if Rails.env.development?
      Rails.logger.debug "WHAPI sending to dynamic endpoint: #{endpoint}"
    end

    # Build query parameters as required by Whapi
    query_params = build_whapi_send_params(phone_number, message, attachment, whapi_type)

    # Download the file content for the request body
    file_content = download_attachment_content(attachment)
    content_type = get_whapi_content_type(attachment, whapi_type)

    if Rails.env.development?
      Rails.logger.debug "WHAPI content type: #{content_type}"
      Rails.logger.debug "WHAPI file size: #{file_content.size} bytes"
    end

    response = safe_http_request('whapi_send_attachment') do
      HTTParty.post(
        endpoint,
        query: query_params,
        headers: {
          'Authorization' => "Bearer #{provider_config_object.api_key}",
          'Content-Type' => content_type
        },
        body: file_content
      )
    end
    process_response(response, message)
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
        safe_http_request('whapi_download_media') do
          HTTParty.get(converted_url).body
        end
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