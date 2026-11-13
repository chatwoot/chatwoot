# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  def perform
    super
  rescue CustomExceptions::WhatsappMediaDownloadError => e
    # Record authorization failures after the message transaction has rolled back.
    inbox.channel.authorization_error! if e.http_status == 401
    raise
  end

  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )

    raise CustomExceptions::WhatsappMediaDownloadError.new(attachment_payload[:id], url_response.code) unless url_response.success?

    downloaded_file = Down.download(url_response.parsed_response.fetch('url'), headers: inbox.channel.api_headers)
    # WhatsApp Cloud sends the original filename in the payload; preserve it so accented
    # names keep their correct extension instead of relying on the mangled remote metadata.
    filename = attachment_payload[:filename]
    downloaded_file.define_singleton_method(:original_filename) { filename } if filename.present?
    downloaded_file
  end
end
