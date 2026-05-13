class Whatsapp::TemplateMediaUploaderService
  WHATSAPP_API_VERSION = 'v23.0'.freeze
  HTTP_TIMEOUT = 120

  ALLOWED_MIME_TYPES = {
    'IMAGE' => %w[image/jpeg image/png].freeze,
    'VIDEO' => %w[video/mp4 video/3gpp].freeze,
    'DOCUMENT' => %w[application/pdf].freeze
  }.freeze

  MAX_FILE_SIZE = {
    'IMAGE' => 5 * 1024 * 1024,
    'VIDEO' => 16 * 1024 * 1024,
    'DOCUMENT' => 100 * 1024 * 1024
  }.freeze

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def upload(io:, file_size:, mime_type:, header_format:)
    validate_file!(file_size, mime_type, header_format)

    app_id = fetch_or_discover_app_id
    raise StandardError, 'Unable to determine app_id from access token. Verify the api_key has whatsapp_business_management scope.' if app_id.blank?

    upload_session_id = create_upload_session(app_id, file_size, mime_type)
    raise StandardError, 'Failed to create upload session with Meta' if upload_session_id.blank?

    upload_file_bytes(upload_session_id, io, mime_type)
  end

  private

  def validate_file!(file_size, mime_type, header_format)
    allowed_types = ALLOWED_MIME_TYPES[header_format]
    raise ArgumentError, 'Header format must be IMAGE, VIDEO, or DOCUMENT' if allowed_types.nil?

    unless allowed_types.include?(mime_type)
      raise ArgumentError, "MIME type '#{mime_type}' not allowed for #{header_format}. Allowed: #{allowed_types.join(', ')}"
    end

    max_size = MAX_FILE_SIZE[header_format]
    if file_size > max_size
      raise ArgumentError, "File too large for #{header_format}. Max allowed: #{max_size / 1024 / 1024} MB"
    end

    raise ArgumentError, 'File is empty' if file_size <= 0
  end

  def fetch_or_discover_app_id
    cached = @whatsapp_channel.provider_config['app_id']
    return cached if cached.present?

    discovered = discover_app_id_via_debug_token
    return nil if discovered.blank?

    cache_app_id(discovered)
    discovered
  end

  def discover_app_id_via_debug_token
    token = @whatsapp_channel.provider_config['api_key']
    response = HTTParty.get(
      "#{api_base_path}/#{WHATSAPP_API_VERSION}/debug_token",
      query: { input_token: token, access_token: token },
      timeout: HTTP_TIMEOUT
    )

    unless response.success?
      Rails.logger.error "WhatsApp debug_token failed: #{response.code} - #{response.body}"
      return nil
    end

    response.dig('data', 'app_id')
  end

  def cache_app_id(app_id)
    config = @whatsapp_channel.provider_config.merge('app_id' => app_id)
    @whatsapp_channel.update_column(:provider_config, config)
  end

  def create_upload_session(app_id, file_size, mime_type)
    response = HTTParty.post(
      "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{app_id}/uploads",
      query: {
        file_length: file_size,
        file_type: mime_type,
        access_token: @whatsapp_channel.provider_config['api_key']
      },
      timeout: HTTP_TIMEOUT
    )

    unless response.success?
      Rails.logger.error "WhatsApp create upload session failed: #{response.code} - #{response.body}"
      raise StandardError, parse_meta_error(response.body) || 'Failed to create upload session'
    end

    response['id']
  end

  def upload_file_bytes(upload_session_id, io, mime_type)
    response = HTTParty.post(
      "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{upload_session_id}",
      headers: {
        'Authorization' => "OAuth #{@whatsapp_channel.provider_config['api_key']}",
        'file_offset' => '0',
        'Content-Type' => mime_type
      },
      body: io.read,
      timeout: HTTP_TIMEOUT
    )

    unless response.success?
      Rails.logger.error "WhatsApp upload bytes failed: #{response.code} - #{response.body}"
      raise StandardError, parse_meta_error(response.body) || 'Failed to upload file bytes to Meta'
    end

    handle = response['h']
    raise StandardError, 'Upload succeeded but no handle was returned by Meta' if handle.blank?

    handle
  end

  def parse_meta_error(body)
    return nil if body.blank?

    parsed = JSON.parse(body)
    err = parsed['error'] || {}
    err['error_user_msg'] || err['message']
  rescue JSON::ParserError
    nil
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
