# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
# Media must be fetched via Graph API (GET /{media_id}) to get a stable download URL;
# the webhook's lookaside.fbsbx.com URL is ephemeral and often fails with Connection reset.

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  DOWNLOAD_OPEN_TIMEOUT = 20
  DOWNLOAD_READ_TIMEOUT = 20
  DOWNLOAD_MAX_RETRIES = 2 # retry connection resets / transient network errors

  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  # Called from base service with the full attachment hash (e.g. message["image"], message["document"]).
  # We only use media_id from it; we never use any "url" field from the webhook payload.
  def download_attachment_file(attachment_payload)
    media_id = attachment_payload[:id] || attachment_payload['id']
    return if media_id.blank?

    # 1) Get stable download URL from Graph API (do not use any url from the webhook payload)
    media_url = fetch_media_url_from_graph(media_id)
    return if media_url.blank?

    Rails.logger.info(
      "WhatsApp media download: media_id=#{media_id} url=#{media_url}"
    )

    # 2) Download; Cloud API requires Authorization header. Retry on connection resets (transient).
    download_with_retries(media_url, media_id)
  rescue Down::Error, IOError => e
    Rails.logger.warn(
      "WhatsApp media download failed for media_id=#{media_id}: #{e.class} - #{e.message}"
    )
    nil
  end

  def download_with_retries(media_url, media_id)
    attempt = 0
    begin
      Down.download(
        media_url,
        headers: inbox.channel.api_headers,
        open_timeout: DOWNLOAD_OPEN_TIMEOUT,
        read_timeout: DOWNLOAD_READ_TIMEOUT
      )
    rescue Down::ConnectionError, IOError => e
      attempt += 1
      retryable = e.is_a?(Down::ConnectionError) || e.message.to_s.include?('reset')
      if retryable && attempt <= DOWNLOAD_MAX_RETRIES
        Rails.logger.warn(
          "WhatsApp media download retry #{attempt}/#{DOWNLOAD_MAX_RETRIES} media_id=#{media_id}: #{e.message}"
        )
        sleep(1 * attempt)
        retry
      end
      raise
    end
  end

  def attach_media_download_failed(_attachment_payload)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :fallback,
      fallback_title: I18n.t('errors.whatsapp.media_download_failed')
    )
  end

  def fetch_media_url_from_graph(media_id)
    response = HTTParty.get(
      inbox.channel.media_url(media_id),
      headers: inbox.channel.api_headers
    )
    Rails.logger.info(
      "WhatsApp Graph media metadata: media_id=#{media_id} status=#{response.code} body=#{response.body}"
    )
    inbox.channel.authorization_error! if response.unauthorized?
    return unless response.success?

    response.parsed_response&.dig('url')
  end
end
