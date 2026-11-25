# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  include Events::Types
  include Whatsapp::GraphRequestOptions

  def perform
    return if processed_params.blank?

    Rails.configuration.dispatcher.dispatch(PROVIDER_EVENT_RECEIVED, Time.zone.now, inbox: inbox, event: whatsapp_cloud_event_type,
                                                                                    payload: processed_params)

    super
  end

  private

  def whatsapp_cloud_event_type
    params.dig(:entry, 0, :changes, 0, :field) || 'unknown'
  end

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers,
      **GRAPH_REQUEST_OPTIONS
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
end
