# rubocop:disable Metrics
class Whatsapp::Providers::WhatsappWebService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, _template_info, message)
    # A API WhatsApp Web Gateway pode não suportar templates complexos
    # Por enquanto, enviamos o conteúdo como mensagem de texto simples
    response = HTTParty.post(
      "#{api_path}/send/message",
      headers: api_headers,
      body: {
        phone: sanitize_number(phone_number),
        message: message.outgoing_content
      }.to_json
    )

    process_response(response, message)
  end

  def sync_templates
    # A API WhatsApp Web Gateway pode não suportar sincronização de templates
    # da mesma forma que a API oficial do WhatsApp
    # Por enquanto, apenas marcamos como atualizado
    whatsapp_channel.mark_message_templates_updated
    whatsapp_channel.update(message_templates: [], message_templates_last_updated: Time.now.utc)
  end

  def validate_provider_config?
    response = HTTParty.get("#{api_path}/app/status", headers: api_headers)
    Rails.logger.debug { "[WHATSAPP] Webhook setup response: #{response.inspect}" }
    response.success?
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Webhook setup failed: #{e.message}"
    false
  end

  def api_headers
    headers = {
      'Content-Type' => 'application/json'
    }

    # Add basic auth if configured
    if whatsapp_channel.provider_config['basic_auth_user'].present? &&
       whatsapp_channel.provider_config['basic_auth_password'].present?
      auth_string = Base64.strict_encode64(
        "#{whatsapp_channel.provider_config['basic_auth_user']}:#{whatsapp_channel.provider_config['basic_auth_password']}"
      )
      headers['Authorization'] = "Basic #{auth_string}"
    end

    headers
  end

  def multipart_headers
    headers = {}

    # Add basic auth if configured
    if whatsapp_channel.provider_config['basic_auth_user'].present? &&
       whatsapp_channel.provider_config['basic_auth_password'].present?
      auth_string = Base64.strict_encode64(
        "#{whatsapp_channel.provider_config['basic_auth_user']}:#{whatsapp_channel.provider_config['basic_auth_password']}"
      )
      headers['Authorization'] = "Basic #{auth_string}"
    end

    headers
  end

  def api_path
    "#{api_base_path}/#{clean_phone_number(whatsapp_channel['phone_number'])}"
  end

  def api_base_path
    ENV.fetch('WHATSAPP_WEB_BASE_URL', whatsapp_channel.provider_config['gateway_base_url'] || 'http://localhost:3001')
  end

  def media_url(media_id)
    # For go-whatsapp-web-multidevice, media_id is the relative path
    # Build the complete URL to the media file directly from base URL
    "#{api_path}/#{media_id.sub(%r{^/}, '')}"
  end

  def avatar_url(identifier)
    response = HTTParty.get(
      "#{api_path}/user/avatar",
      headers: api_headers,
      query: { phone: identifier, is_preview: true }
    )

    raise StandardError, "Gateway avatar failed: #{response.message}" unless response.success?

    response.dig('results', 'url')
  end

  def contact_info(identifier)
    # Retry configuration for transient connection failures
    max_retries = 3
    current_retry = 0
    backoff_seconds = 1

    begin
      # Check if this is a group identifier
      if identifier.include?('@g.us')
        # Use group info endpoint for groups
        response = HTTParty.get(
          "#{api_path}/group/info",
          headers: api_headers,
          query: { group_id: identifier },
          timeout: 10
        )

        raise StandardError, "Gateway group info failed: #{response.message}" unless response.success?

        # Return group name and info
        group_data = response['results']
        group_name = group_data&.dig('name') || group_data&.dig('Name')
        return { name: group_name, type: 'group' } if group_data.present?
      else
        # Use user info endpoint for individual contacts
        response = HTTParty.get(
          "#{api_path}/user/info",
          headers: api_headers,
          query: { phone: identifier },
          timeout: 10
        )

        if response.success? && response['results'].present?
          user_data = response['results']
          user_name = user_data&.dig('pushname') || user_data&.dig('name') || user_data&.dig('Name')
          return { name: user_name, type: 'contact' }
        end

        # Fallback: extract phone number from identifier for display
        phone = identifier.split('@').first
        return { name: "+#{phone}", type: 'contact' }
      end

      nil
    rescue Errno::ECONNREFUSED, Net::OpenTimeout => e
      # Retry on transient connection errors with exponential backoff
      current_retry += 1

      if current_retry <= max_retries
        Rails.logger.info(
          "WhatsApp Web: Retrying contact_info for #{identifier} after #{backoff_seconds}s " \
          "(retry #{current_retry}/#{max_retries}, error: #{e.class.name})"
        )

        sleep(backoff_seconds)
        backoff_seconds *= 2 # Exponential backoff: 1s, 2s, 4s
        retry
      else
        # Exhausted all retries - re-raise error for upstream handling
        Rails.logger.error(
          "WhatsApp Web: Failed to fetch contact_info for #{identifier} after #{max_retries} retries: #{e.message}"
        )
        raise e
      end
    end
  end

  def send_text_message(phone_number, message)
    # Prepare message content with agent display name if sender is present and signature is enabled
    include_signature = whatsapp_channel.provider_config['include_signature']
    message_content = if include_signature && message.sender&.available_name.present?
                        "*#{message.sender.available_name}:*\n #{message.outgoing_content}"
                      else
                        message.outgoing_content
                      end

    payload = {
      phone: sanitize_number(phone_number),
      message: message_content
    }

    # Add reply_message_id if this is a reply to another message
    reply_id = extract_reply_message_id(message)
    payload[:reply_message_id] = reply_id if reply_id.present?

    response = HTTParty.post(
      "#{api_path}/send/message",
      headers: api_headers,
      body: payload.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    sanitized_phone = sanitize_number(phone_number)

    case attachment.file_type
    when 'image'
      send_image_message(sanitized_phone, attachment, message)
    when 'audio'
      send_audio_message(sanitized_phone, attachment, message)
    when 'video'
      send_video_message(sanitized_phone, attachment, message)
    else
      send_file_message(sanitized_phone, attachment, message)
    end
  end

  def send_image_message(phone_number, attachment, message)
    # Validate image type before sending
    unless valid_image_type?(attachment)
      Rails.logger.warn "[WHATSAPP WEB] Unsupported image type: #{attachment.file.content_type}, sending as document"
      return send_file_message(phone_number, attachment, message)
    end

    # Get the appropriate URL for the attachment
    # In production with S3, prefer file_url (Rails redirect) over download_url (direct S3 URL)
    # because the gateway might have issues with S3 URLs or their signed parameters
    image_url = get_accessible_attachment_url(attachment)

    if image_url.blank?
      Rails.logger.error "[WHATSAPP WEB] No accessible URL available for attachment #{attachment.id}"
      return send_file_message(phone_number, attachment, message)
    end

    Rails.logger.debug { "[WHATSAPP WEB] Using image URL: #{image_url}" }

    # Build the request body according to API spec
    body_params = {
      phone: phone_number,
      caption: message.outgoing_content.presence || '',
      view_once: false,
      compress: false,
      image_url: image_url
    }

    # Add reply context if this is a reply
    reply_id = extract_reply_message_id(message)
    body_params[:reply_message_id] = reply_id if reply_id.present?

    response = HTTParty.post(
      "#{api_path}/send/image",
      headers: api_headers,
      body: body_params.to_json
    )

    process_response(response, message)
  end

  def send_audio_message(phone_number, attachment, message)
    # Get the appropriate URL for the attachment
    audio_url = get_accessible_attachment_url(attachment)

    if audio_url.blank?
      Rails.logger.error "[WHATSAPP WEB] No accessible URL available for audio attachment #{attachment.id}"
      return nil
    end

    Rails.logger.debug { "[WHATSAPP WEB] Using audio URL: #{audio_url}" }

    # Build the request body according to API spec
    body_params = {
      phone: phone_number,
      audio_url: audio_url
    }

    # Add reply context if this is a reply
    reply_id = extract_reply_message_id(message)
    body_params[:reply_message_id] = reply_id if reply_id.present?

    response = HTTParty.post(
      "#{api_path}/send/audio",
      headers: api_headers,
      body: body_params.to_json
    )

    process_response(response, message)
  end

  def send_video_message(phone_number, attachment, message)
    # Get the appropriate URL for the attachment
    video_url = get_accessible_attachment_url(attachment)

    if video_url.blank?
      Rails.logger.error "[WHATSAPP WEB] No accessible URL available for video attachment #{attachment.id}"
      return nil
    end

    Rails.logger.debug { "[WHATSAPP WEB] Using video URL: #{video_url}" }

    # Build the request body according to API spec
    body_params = {
      phone: phone_number,
      caption: message.outgoing_content.presence || '',
      view_once: false,
      compress: false,
      video_url: video_url
    }

    # Add reply context if this is a reply
    reply_id = extract_reply_message_id(message)
    body_params[:reply_message_id] = reply_id if reply_id.present?

    response = HTTParty.post(
      "#{api_path}/send/video",
      headers: api_headers,
      body: body_params.to_json
    )

    process_response(response, message)
  end

  def send_file_message(phone_number, attachment, message)
    # The /send/file endpoint requires multipart/form-data upload
    # Download the file from ActiveStorage
    unless attachment.file.attached?
      Rails.logger.error "[WHATSAPP WEB] No file attached for attachment #{attachment.id}"
      return nil
    end

    begin
      # Download file content from ActiveStorage
      file_content = attachment.file.download
      file_name = attachment.file.filename.to_s
      content_type = attachment.file.content_type || 'application/octet-stream'

      Rails.logger.debug { "[WHATSAPP WEB] Uploading file: #{file_name} (#{content_type}, #{file_content.bytesize} bytes)" }

      # Create a temporary file for multipart upload
      Tempfile.create(['upload', File.extname(file_name)]) do |temp_file|
        temp_file.binmode
        temp_file.write(file_content)
        temp_file.rewind

        # Build multipart form data
        body_params = {
          phone: phone_number,
          caption: message.outgoing_content.presence || '',
          file: temp_file
        }

        # Add reply context if this is a reply
        reply_id = extract_reply_message_id(message)
        body_params[:reply_message_id] = reply_id if reply_id.present?

        response = HTTParty.post(
          "#{api_path}/send/file",
          headers: multipart_headers,
          body: body_params,
          multipart: true
        )

        process_response(response, message)
      end
    rescue StandardError => e
      Rails.logger.error "[WHATSAPP WEB] File upload failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

  def error_message(response)
    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    response.parsed_response&.dig('error', 'message')
  end

  def template_body_parameters(template_info)
    template_body = {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      }
    }

    # Enhanced template parameters structure
    # Note: Legacy format support (simple parameter arrays) has been removed
    # in favor of the enhanced component-based structure that supports
    # headers, buttons, and authentication templates.
    #
    # Expected payload format from frontend:
    # {
    #   processed_params: {
    #     body: { '1': 'John', '2': '123 Main St' },
    #     header: { media_url: 'https://...', media_type: 'image' },
    #     buttons: [{ type: 'url', parameter: 'otp123456' }]
    #   }
    # }
    # This gets transformed into WhatsApp API component format:
    # [
    #   { type: 'body', parameters: [...] },
    #   { type: 'header', parameters: [...] },
    #   { type: 'button', sub_type: 'url', parameters: [...] }
    # ]
    template_body[:components] = template_info[:parameters] || []

    template_body
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  # Gateway methods for WhatsApp Web connection
  def connect
    response = HTTParty.get(
      "#{api_path}/app/login",
      headers: api_headers
    )

    Rails.logger.debug { "[WHATSAPP_WEB] Gateway login response: #{response.inspect}" }

    raise StandardError, "Gateway login failed: #{response.message}" unless response.success?

    response.parsed_response
  end

  def gateway_login_with_code(phone_number)
    response = HTTParty.get(
      "#{api_path}/app/login-with-code",
      query: { phone: sanitize_number(phone_number) },
      headers: api_headers
    )

    Rails.logger.debug { "[WHATSAPP_WEB] Gateway login with code response: #{response.inspect}" }

    raise StandardError, "Gateway login with code failed: #{response.message}" unless response.success?

    response.parsed_response
  end

  def gateway_devices
    response = HTTParty.get(
      "#{api_path}/app/devices",
      headers: api_headers
    )

    Rails.logger.debug { "[WHATSAPP_WEB] Gateway devices response: #{response.inspect}" }

    raise StandardError, "Gateway devices failed: #{response.message}" unless response.success?

    response.parsed_response
  end

  def gateway_logout
    response = HTTParty.get(
      "#{api_path}/app/logout",
      headers: api_headers
    )

    Rails.logger.debug { "[WHATSAPP_WEB] Gateway logout response: #{response.inspect}" }

    raise StandardError, "Gateway logout failed: #{response.message}" unless response.success?

    response.parsed_response
  end

  def gateway_reconnect
    response = HTTParty.get(
      "#{api_path}/app/reconnect",
      headers: api_headers
    )

    Rails.logger.debug { "[WHATSAPP_WEB] Gateway reconnect response: #{response.inspect}" }

    raise StandardError, "Gateway reconnect failed: #{response.message}" unless response.success?

    response.parsed_response
  end

  def connection_status
    response = HTTParty.get(
      "#{api_path}/app/status",
      headers: api_headers
    )

    Rails.logger.debug { "[WHATSAPP_WEB] Gateway connection status response: #{response.inspect}" }

    raise StandardError, "Gateway connection status failed: #{response.message}" unless response.success?

    response.parsed_response
  end

  def connect_with_qr_conversion
    result = connect
    convert_qr_to_base64(result)
    result
  end

  def test_connection_with_qr_conversion
    result = connect
    convert_qr_to_base64(result)
    result
  end

  private

  def convert_qr_to_base64(result)
    return if result.dig('results', 'qr_link').blank?

    original_qr_link = result['results']['qr_link']
    Rails.logger.debug { "[WHATSAPP_WEB] Converting QR link: #{original_qr_link}" }

    begin
      qr_result = fetch_qr_code_image(original_qr_link)

      if qr_result[:success]
        base64_data = Base64.strict_encode64(qr_result[:data])
        data_url = "data:#{qr_result[:content_type]};base64,#{base64_data}"
        result['results']['qr_link'] = data_url
        Rails.logger.info '[WHATSAPP_WEB] Converted QR code to base64 data URL'
      else
        Rails.logger.warn "[WHATSAPP_WEB] Failed to fetch QR code: #{qr_result[:error]}"
      end
    rescue StandardError => e
      Rails.logger.error "[WHATSAPP_WEB] QR code conversion error: #{e.message}"
    end
  end

  def send_interactive_text_message(phone_number, message)
    # Para mensagens interativas, usamos o endpoint de mensagem padrão
    # pois a API WhatsApp Web Gateway pode não suportar mensagens interativas complexas
    response = HTTParty.post(
      "#{api_path}/send/message",
      headers: api_headers,
      body: {
        phone: sanitize_number(phone_number),
        message: message.outgoing_content
      }.to_json
    )

    process_response(response, message)
  end

  def proxy_qr_code(qr_path)
    # Build full URL to the QR code image
    qr_url = "#{gateway_base_url}/#{sanitize_number(whatsapp_channel.phone_number)}/#{qr_path}"

    Rails.logger.debug { "[WHATSAPP_WEB] Proxying QR code from: #{qr_url}" }

    # Fetch the QR code image from the gateway
    response = HTTParty.get(qr_url, headers: api_headers)

    if response.success?
      {
        success: true,
        data: response.body,
        content_type: response.headers['content-type'] || 'image/png'
      }
    else
      Rails.logger.error "[WHATSAPP_WEB] QR code proxy failed: #{response.code} - #{response.message}"
      {
        success: false,
        error: "Failed to fetch QR code: #{response.message}"
      }
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] QR code proxy exception: #{e.message}"
    {
      success: false,
      error: "QR code proxy error: #{e.message}"
    }
  end

  def fetch_qr_code_image(qr_url)
    Rails.logger.debug { "[WHATSAPP_WEB] Fetching QR code image from: #{qr_url}" }

    # Fetch the QR code image from the gateway
    response = HTTParty.get(qr_url, headers: api_headers)

    if response.success?
      {
        success: true,
        data: response.body,
        content_type: response.headers['content-type'] || 'image/png'
      }
    else
      Rails.logger.error "[WHATSAPP_WEB] QR code fetch failed: #{response.code} - #{response.message}"
      {
        success: false,
        error: "Failed to fetch QR code: #{response.message}"
      }
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] QR code fetch exception: #{e.message}"
    {
      success: false,
      error: "QR code fetch error: #{e.message}"
    }
  end

  def process_response(response, message)
    # Log HTTP response status for debugging
    Rails.logger.debug { "[WHATSAPP WEB] HTTP Status: #{response.code}, Body: #{response.body}" }

    parsed_response = JSON.parse(response.body) if response.body.present?
    return nil unless parsed_response

    # Handle go-whatsapp-web-multidevice API response format:
    # {
    #   "code": "SUCCESS",
    #   "message": "Success",
    #   "results": {
    #     "message_id": "3EB0B430B6F8F1D0E053AC120E0A9E5C",
    #     "status": "<feature> success ...."
    #   }
    # }
    if parsed_response['code'] == 'SUCCESS' && parsed_response['results'].present?
      message_id = parsed_response.dig('results', 'message_id')
      if message_id.present?
        Rails.logger.info "[WHATSAPP WEB] Message sent successfully with ID: #{message_id}"
        # Update message with source_id for receipt tracking
        message&.update!(source_id: message_id)
        return message_id
      end
    end

    # Log detailed error information
    error_code = parsed_response['code']
    error_message = parsed_response['message']
    Rails.logger.error "[WHATSAPP WEB] Message send failed - Code: #{error_code}, Message: #{error_message}, Full response: #{parsed_response}"

    # Raise specific error for better upstream handling
    if error_code == 'INTERNAL_SERVER_ERROR' && error_message&.include?('unsupported file type')
      raise StandardError, "Unsupported file type for WhatsApp Web Gateway: #{error_message}"
    end

    nil
  end

  def sanitize_number(number)
    # Remove any formatting and prefixes
    clean_number = number.to_s.strip.delete_prefix('+')

    # Preserve group JIDs (format: digits@g.us)
    return clean_number if clean_number.include?('@g.us')
    # The API expects the format: number@s.whatsapp.net
    # Check if it already has the suffix
    return clean_number if clean_number.include?('@s.whatsapp.net')

    "#{clean_number}@s.whatsapp.net"
  end

  def clean_phone_number(number)
    # For API path construction - return only digits
    number.to_s.strip.delete_prefix('+').split('@').first
  end

  def extract_reply_message_id(message)
    # Extract reply message ID from content attributes
    # This corresponds to in_reply_to_external_id from the frontend
    message.content_attributes&.dig('in_reply_to_external_id')
  end

  def valid_image_type?(attachment)
    # WhatsApp supports: JPEG, PNG, WEBP
    supported_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
    content_type = attachment.file.content_type&.downcase

    supported_types.include?(content_type)
  end

  def get_accessible_attachment_url(attachment)
    return nil unless attachment.file.attached?

    # In production environments with external storage (S3, etc.),
    # the direct download URL might not be accessible by external services
    # due to CORS restrictions or signed URL issues.
    # Try different URL strategies in order of preference.

    # Strategy 1: Use file_url (Rails redirect) for better compatibility
    # This uses Rails' own redirect mechanism which handles storage backends better
    file_url = attachment.file_url
    return file_url if file_url.present?

    # Strategy 2: Fallback to download_url if file_url is not available
    download_url = attachment.download_url
    return download_url if download_url.present?

    # Strategy 3: Use external_url if available (for already external assets)
    return attachment.external_url if attachment.external_url.present?

    Rails.logger.warn "[WHATSAPP WEB] No accessible URL found for attachment #{attachment.id}"
    nil
  end
end
# rubocop:enable Metrics
