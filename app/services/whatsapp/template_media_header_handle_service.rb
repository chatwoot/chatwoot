class Whatsapp::TemplateMediaHeaderHandleService
  WHATSAPP_API_VERSION = 'v22.0'.freeze
  MAX_MEDIA_BYTES = 5.megabytes
  SUPPORTED_CONTENT_TYPES = %w[image/jpeg image/png].freeze

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def generate(media_url:, file_name: nil)
    return failure('Header media URL is required') if media_url.blank?
    return failure('WHATSAPP_APP_ID is required to upload template header media') if app_id.blank?

    downloaded_file = download_media(media_url)
    content_type = media_content_type(downloaded_file)
    return failure("Unsupported header media type: #{content_type}") unless SUPPORTED_CONTENT_TYPES.include?(content_type)

    session = create_upload_session(
      file_name: file_name.presence || file_name_from_url(media_url, content_type),
      file_length: downloaded_file.size,
      file_type: content_type
    )
    return session unless session[:success]

    upload_to_session(session_id: session[:upload_session_id], file: downloaded_file, file_type: content_type)
  rescue Down::Error => e
    failure("Header media download failed: #{e.message}")
  rescue StandardError => e
    failure("Header media upload failed: #{e.message}")
  ensure
    close_download(downloaded_file)
  end

  private

  def download_media(media_url)
    Down.download(media_url, max_size: MAX_MEDIA_BYTES)
  end

  def media_content_type(downloaded_file)
    downloaded_file.content_type.to_s.presence
  end

  def create_upload_session(file_name:, file_length:, file_type:)
    response = HTTParty.post(
      "#{api_base_path}/#{api_version}/#{app_id}/uploads",
      headers: authorization_headers,
      query: {
        file_name: file_name,
        file_length: file_length,
        file_type: file_type
      }
    )
    return meta_failure(response, 'Header media upload session failed') unless response.success?

    upload_session_id = response['id'].presence
    return failure('Header media upload session did not return an id') if upload_session_id.blank?

    { success: true, upload_session_id: upload_session_id }
  end

  def upload_to_session(session_id:, file:, file_type:)
    file.binmode if file.respond_to?(:binmode)
    file.rewind
    response = HTTParty.post(
      "#{api_base_path}/#{api_version}/#{session_id}",
      headers: {
        'Authorization' => "OAuth #{access_token}",
        'Content-Type' => file_type,
        'file_offset' => '0'
      },
      body: file.read
    )
    return meta_failure(response, 'Header media upload failed') unless response.success?

    header_handle = response['h'].presence
    return failure('Header media upload did not return a handle') if header_handle.blank?

    { success: true, header_handle: header_handle }
  end

  def file_name_from_url(media_url, content_type)
    basename = URI.parse(media_url).path.to_s.split('/').last
    return basename if basename.present?

    content_type == 'image/png' ? 'header.png' : 'header.jpg'
  rescue URI::InvalidURIError
    content_type == 'image/png' ? 'header.png' : 'header.jpg'
  end

  def close_download(downloaded_file)
    return if downloaded_file.blank?

    if downloaded_file.respond_to?(:close!)
      downloaded_file.close!
    elsif downloaded_file.respond_to?(:close)
      downloaded_file.close
    end
  end

  def meta_failure(response, fallback)
    details = Whatsapp::TemplateMetaErrorDetails.from(response)
    details.merge(
      success: false,
      response_code: response.code,
      error: details[:error].presence || fallback
    )
  end

  def failure(message)
    { success: false, error: message }
  end

  def authorization_headers
    { 'Authorization' => "Bearer #{access_token}" }
  end

  def access_token
    @whatsapp_channel.provider_config['api_key']
  end

  def app_id
    @app_id ||= Whatsapp::AppIdResolver.new(@whatsapp_channel).find
  end

  def api_version
    GlobalConfigService.load('WHATSAPP_API_VERSION', WHATSAPP_API_VERSION)
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
