# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    media_url = resolve_media_download_url(attachment_payload)
    return if media_url.blank?

    downloaded_file = Down.download(media_url, headers: inbox.channel.api_headers)
    # WhatsApp Cloud sends the original filename in the payload; preserve it so accented
    # names keep their correct extension instead of relying on the mangled remote metadata.
    filename = attachment_payload[:filename]
    downloaded_file.define_singleton_method(:original_filename) { filename } if filename.present?
    downloaded_file
  rescue Down::Error, Down::ClientError => e
    Rails.logger.warn(
      "[WhatsApp] media download failed inbox=#{inbox.id} media_id=#{attachment_payload[:id]} error=#{e.class}: #{e.message}"
    )
    nil
  end

  def resolve_media_download_url(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )

    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?
    return url_response.parsed_response['url'] if url_response.success?

    # SMB / coexistence webhooks often include a short-lived CDN URL already.
    fallback = attachment_payload[:url].presence
    if fallback.present?
      Rails.logger.warn(
        "[WhatsApp] Graph media lookup failed (#{url_response.code}); " \
        "using webhook URL for media_id=#{attachment_payload[:id]}"
      )
      return fallback
    end

    Rails.logger.warn(
      "[WhatsApp] media lookup failed inbox=#{inbox.id} code=#{url_response.code} " \
      "media_id=#{attachment_payload[:id]} body=#{url_response.body.to_s.first(200)}"
    )
    nil
  end
end
