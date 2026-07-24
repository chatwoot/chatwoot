# frozen_string_literal: true

# Uploads a file attachment directly to the WhatsApp Cloud API media endpoint
# and returns the resulting media_id.
#
# Using media_id instead of a link URL completely bypasses Meta's fwdproxy
# download path, which is rate-limited per destination ASN. This prevents
# intermittent 131053 errors for self-hosted instances sharing a hosting
# provider with other Chatwoot/Evolution API deployments.
#
# See: https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#upload-media
class Whatsapp::MediaUploadService
  WHATSAPP_SUPPORTED_TYPES = %w[
    audio/aac audio/mp4 audio/mpeg audio/amr audio/ogg audio/opus
    application/pdf
    image/jpeg image/png image/webp
    video/mp4 video/3gpp
    application/vnd.ms-powerpoint application/msword
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-excel text/plain
  ].freeze

  def initialize(channel:, attachment:)
    @channel = channel
    @attachment = attachment
  end

  # Returns the media_id string on success, raises on failure.
  def upload
    file_content = @attachment.file.download
    mime_type = @attachment.file.content_type.presence || 'application/octet-stream'
    filename = @attachment.file.filename.to_s

    response = HTTParty.post(
      upload_url,
      headers: auth_header,
      body: build_multipart_body(file_content, mime_type, filename),
      multipart: true
    )

    raise upload_error(response) unless response.success?

    media_id = response.parsed_response['id']
    raise '[WhatsApp Media Upload] API returned success but no media_id in response' if media_id.blank?

    media_id
  rescue StandardError => e
    Rails.logger.error("[WhatsApp Media Upload] Failed for attachment #{@attachment.id}: #{e.message}")
    raise
  end

  private

  def upload_url
    base = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    phone_number_id = @channel.provider_config['phone_number_id']
    "#{base}/v18.0/#{phone_number_id}/media"
  end

  def auth_header
    { 'Authorization' => "Bearer #{@channel.provider_config['api_key']}" }
  end

  def build_multipart_body(file_content, mime_type, filename)
    {
      messaging_product: 'whatsapp',
      type: mime_type,
      file: UploadIO.new(StringIO.new(file_content), mime_type, filename)
    }
  end

  def upload_error(response)
    error_msg = response.parsed_response.is_a?(Hash) ? response.parsed_response.dig('error', 'message') : response.body
    "[WhatsApp Media Upload] HTTP #{response.code}: #{error_msg}"
  end
end
