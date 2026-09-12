require 'faraday/multipart'

# Uploads an attachment to the WhatsApp Cloud media endpoint and returns its media_id.
# Sending media by id keeps Meta from fetching the file from us over fwdproxy, which rate limits per
# destination ASN and returns intermittent 131053 errors when instances share a hosting provider.
# ref: https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#upload-media
class Whatsapp::MediaUploadService
  WHATSAPP_API_VERSION_FALLBACK = 'v22.0'.freeze
  OPEN_TIMEOUT = 60
  TIMEOUT = 300

  def initialize(whatsapp_channel, attachment)
    @whatsapp_channel = whatsapp_channel
    @attachment = attachment
  end

  # Returns the media object to send ({ 'id' => media_id }), or nil when the upload is disabled or fails.
  def perform
    return unless direct_upload_enabled? && @attachment.file.attached?

    response = upload
    media_id = response.body['id'] if response.body.is_a?(Hash)
    return { 'id' => media_id } if response.success? && media_id.present?

    log_failure("HTTP #{response.status} #{error_message(response)}")
  rescue Faraday::Error, ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError => e
    log_failure("#{e.class.name} #{e.message}")
  end

  private

  # Escape hatch for operators: WHATSAPP_MEDIA_UPLOAD_STRATEGY=link restores link based sending.
  def direct_upload_enabled?
    ENV.fetch('WHATSAPP_MEDIA_UPLOAD_STRATEGY', 'direct') == 'direct'
  end

  def upload
    blob = @attachment.file.blob

    blob.open do |file|
      connection.post(upload_url) do |request|
        request.headers['Authorization'] = "Bearer #{@whatsapp_channel.provider_config['api_key']}"
        request.body = {
          messaging_product: 'whatsapp',
          type: blob.content_type,
          file: Faraday::Multipart::FilePart.new(file, blob.content_type, blob.filename.to_s)
        }
      end
    end
  end

  def connection
    @connection ||= Faraday.new do |f|
      f.request :multipart
      f.response :json
      f.options.timeout = TIMEOUT
      f.options.open_timeout = OPEN_TIMEOUT
    end
  end

  def upload_url
    base_path = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    version = GlobalConfigService.load('WHATSAPP_API_VERSION', WHATSAPP_API_VERSION_FALLBACK)
    "#{base_path}/#{version}/#{@whatsapp_channel.provider_config['phone_number_id']}/media"
  end

  def error_message(response)
    return response.body.dig('error', 'message') if response.body.is_a?(Hash)

    response.body.to_s.truncate(200)
  end

  def log_failure(reason)
    Rails.logger.warn("[WHATSAPP] Media upload failed, falling back to link for account #{@whatsapp_channel.account_id} " \
                      "inbox #{@whatsapp_channel.inbox&.id} attachment #{@attachment.id}: #{reason}")
    nil
  end
end
