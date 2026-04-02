# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    # Try direct URL from webhook first (new WhatsApp Cloud API format)
    direct_url = attachment_payload[:url] || attachment_payload['url']
    if direct_url.present?
      file = download_from_direct_url(direct_url)
      return file if file.present?
    end

    # Fallback to Media API
    download_via_media_api(attachment_payload)
  end

  def download_from_direct_url(url)
    Down.download(url, headers: inbox.channel.api_headers)
  rescue Down::Error
    nil
  end

  def download_via_media_api(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )
    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?
    Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers) if url_response.success?
  end
end
