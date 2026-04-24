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
    return downloaded_file if attachment_payload[:filename].blank?

    tempfile_with_original_filename(downloaded_file, attachment_payload[:filename])
  end

  def tempfile_with_original_filename(downloaded_file, filename)
    tempfile = Tempfile.new(
      [
        File.basename(filename, '.*'),
        File.extname(filename)
      ]
    )

    FileUtils.cp(downloaded_file.path, tempfile.path)

    tempfile.define_singleton_method(:content_type) { downloaded_file.content_type }
    tempfile.define_singleton_method(:original_filename) { filename }

    tempfile
  end
end
