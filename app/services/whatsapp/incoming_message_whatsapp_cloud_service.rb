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

  file = Down.download(
    url_response.parsed_response['url'],
    headers: inbox.channel.api_headers
  )

  # Fix: explicitly preserve original filename from WhatsApp payload
  if attachment_payload[:filename].present?
    filename = attachment_payload[:filename]
    file.define_singleton_method(:original_filename) { filename }
  end

  file
end