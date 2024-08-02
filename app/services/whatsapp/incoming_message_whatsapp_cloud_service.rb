# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= deep_symbolize_keys(params)[:entry].try(:first).try(:[], :changes).try(:first).try(:[], :value)
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?
    Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers) if url_response.success?
  end

  def deep_symbolize_keys(hash)
    case hash
    when Array
      hash.map { |v| deep_symbolize_keys(v) }
    when Hash
      hash.each_with_object({}) do |(k, v), acc|
        sym_key = k.is_a?(String) ? k.to_sym : k
        acc[sym_key] = deep_symbolize_keys(v)
      end
    else
      hash
    end
  end
end
