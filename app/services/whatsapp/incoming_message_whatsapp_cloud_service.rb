# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    Rails.logger.debug { "[WHATSAPP CLOUD] Obteniendo URL temporal para attachment: #{attachment_payload[:id]}" }

    url_response = HTTParty.get(
      inbox.channel.media_url(
        attachment_payload[:id],
        inbox.channel.provider_config['phone_number_id']
      ),
      headers: inbox.channel.api_headers
    )

    # This url response will be failure if the access token has expired.
    if url_response.unauthorized?
      Rails.logger.error '[WHATSAPP CLOUD] Token NO autorizado (401). Re-autenticación necesaria.'
      inbox.channel.authorization_error!
      return nil
    end

    unless url_response.success?
      Rails.logger.error "[WHATSAPP CLOUD] Error obteniendo URL: HTTP #{url_response.code} - #{url_response.body}"
      return nil
    end

    download_url = url_response.parsed_response['url']

    if download_url.blank?
      Rails.logger.error "[WHATSAPP CLOUD] URL de descarga vacía en respuesta: #{url_response.parsed_response.inspect}"
      return nil
    end

    Rails.logger.debug { "[WHATSAPP CLOUD] Descargando desde URL temporal: #{download_url[0..50]}..." }

    Down.download(download_url, headers: inbox.channel.api_headers)
  rescue Down::Error => e
    Rails.logger.error "[WHATSAPP CLOUD] Down::Error al descargar: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CLOUD] Error inesperado: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    nil
  end
end
