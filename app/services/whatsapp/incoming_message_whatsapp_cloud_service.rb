# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
# Media must be fetched via Graph API (GET /{media_id}) to get a stable download URL;
# the webhook's lookaside.fbsbx.com URL is ephemeral and often fails with Connection reset.

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  DOWNLOAD_OPEN_TIMEOUT = 20
  DOWNLOAD_READ_TIMEOUT = 20

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

    # 2) Download from lookaside URL; Cloud API requires Authorization header on this request too.
    tempfile = Down.download(
      media_url,
      headers: inbox.channel.api_headers,
      open_timeout: DOWNLOAD_OPEN_TIMEOUT,
      read_timeout: DOWNLOAD_READ_TIMEOUT
    )
    tempfile
  rescue Down::Error, IOError => e
    Rails.logger.warn(
      "WhatsApp media download failed for media_id=#{media_id}: #{e.class} - #{e.message}"
    )
    nil
  end

  def fetch_media_url_from_graph(media_id)
    response = HTTParty.get(
      inbox.channel.media_url(media_id),
      headers: inbox.channel.api_headers
    )
    inbox.channel.authorization_error! if response.unauthorized?
    return unless response.success?

    response.parsed_response&.dig('url')
  end
end
