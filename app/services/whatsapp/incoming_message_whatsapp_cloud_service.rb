# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    # Timeout para obter a URL do media (30 segundos)
    url_response = HTTParty.get(
      inbox.channel.media_url(
        attachment_payload[:id],
        inbox.channel.provider_config['phone_number_id']
      ),
      headers: inbox.channel.api_headers,
      timeout: ENV.fetch('WHATSAPP_MEDIA_URL_TIMEOUT', 30).to_i
    )
    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?

    return unless url_response.success?

    # Timeout para download do arquivo (36000 segundos = 10 horas para vídeos grandes)
    media_url = url_response.parsed_response['url']
    Down.download(
      media_url,
      headers: inbox.channel.api_headers,
      read_timeout: ENV.fetch('WHATSAPP_MEDIA_DOWNLOAD_TIMEOUT', 36000).to_i,
      open_timeout: ENV.fetch('WHATSAPP_MEDIA_OPEN_TIMEOUT', 60).to_i
    )
  end
end
