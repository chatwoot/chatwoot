# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )

    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?

    return unless url_response.success?

    downloaded_file = Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers)
    # Voice notes omit filename; without an .ogg extension Marcel may misidentify the blob.
    filename = attachment_payload[:filename].presence || default_download_filename(attachment_payload)
    downloaded_file.define_singleton_method(:original_filename) { filename } if filename.present?
    downloaded_file
  end

  def default_download_filename(attachment_payload)
    mime = attachment_payload[:mime_type].to_s.split(';').first.strip
    return unless mime.start_with?('audio/')

    extension = mime == 'audio/mpeg' ? 'mp3' : mime.split('/').last
    "whatsapp-audio-#{attachment_payload[:id]}.#{extension}"
  end
end
