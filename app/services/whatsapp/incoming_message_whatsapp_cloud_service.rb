# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    # Unofficial (Baileys) companion serves the raw bytes directly at media_url,
    # not a JSON wrapper with a `url` field like Graph API. Branch so we don't
    # try to parse binary PNG as JSON.
    if inbox.channel.provider == 'whatsapp_unofficial'
      return download_unofficial_attachment(attachment_payload)
    end

    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )

    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?

    return unless url_response.success?

    downloaded_file = Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers)
    # WhatsApp Cloud sends the original filename in the payload; preserve it so accented
    # names keep their correct extension instead of relying on the mangled remote metadata.
    filename = attachment_payload[:filename]
    downloaded_file.define_singleton_method(:original_filename) { filename } if filename.present?
    downloaded_file
  end

  def download_unofficial_attachment(attachment_payload)
    response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )

    inbox.channel.authorization_error! if response.unauthorized?
    return unless response.success?

    # Response is raw binary; wrap it in a Tempfile so ActiveStorage can attach it.
    filename = attachment_payload[:filename].presence || "media-#{attachment_payload[:id]}"
    content_type = response.headers['content-type'].presence || response.headers['Content-Type'].presence || 'application/octet-stream'
    tempfile = Tempfile.new(['whatsapp_unofficial', File.extname(filename)])
    tempfile.binmode
    tempfile.write(response.body)
    tempfile.rewind

    # Make it quack like a Down::Chunk / File for ActiveStorage
    tempfile.define_singleton_method(:original_filename) { filename }
    tempfile.define_singleton_method(:content_type) { content_type }

    tempfile
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP_UNOFFICIAL] media download failed for #{attachment_payload[:id]}: #{e.class} #{e.message}")
    nil
  end
end
