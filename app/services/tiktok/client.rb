require 'net/http/post/multipart'

class Tiktok::Client
  # Always use Tiktok::TokenService to get a valid access token
  pattr_initialize [:business_id!, :access_token!]

  def business_account_details
    endpoint = "#{api_base_url}/business/get/"
    headers = { 'Access-Token': access_token }
    params = { business_id: business_id, fields: %w[username display_name profile_image].to_s }
    response = HTTParty.get(endpoint, query: params, headers: headers)

    json = process_json_response(response, 'Failed to fetch TikTok user details')
    {
      username: json['data']['username'],
      display_name: json['data']['display_name'],
      profile_image: json['data']['profile_image']
    }.with_indifferent_access
  end

  def file_download_url(conversation_id, message_id, media_id, media_type = 'IMAGE')
    endpoint = "#{api_base_url}/business/message/media/download/"
    headers = { 'Access-Token': access_token, 'Content-Type': 'application/json', Accept: 'application/json' }
    body = { business_id: business_id,
             conversation_id: conversation_id,
             message_id: message_id,
             media_id: media_id,
             media_type: media_type }

    response = HTTParty.post(endpoint, body: body.to_json, headers: headers)
    json = process_json_response(response, 'Failed to fetch TikTok media download URL')

    json['data']['download_url']
  end

  def send_text_message(conversation_id, text, referenced_message_id: nil)
    send_message(conversation_id, 'TEXT', text, referenced_message_id: referenced_message_id)
  end

  def send_media_message(conversation_id, attachment, referenced_message_id: nil)
    # As of now, only IMAGE media type is supported
    media_id = upload_media(attachment.file.blob, 'IMAGE')
    send_message(conversation_id, 'IMAGE', media_id, referenced_message_id: referenced_message_id)
  end

  private

  def send_message(conversation_id, type, payload, referenced_message_id: nil)
    # https://business-api.tiktok.com/portal/docs?id=1832184403754242
    endpoint = "#{api_base_url}/business/message/send/"
    headers = { 'Access-Token': access_token, 'Content-Type': 'application/json' }
    body = {
      business_id: business_id,
      recipient_type: 'CONVERSATION',
      recipient: conversation_id
    }

    body[:referenced_message_info] = { referenced_message_id: referenced_message_id } if referenced_message_id.present?

    if type == 'IMAGE'
      body[:message_type] = 'IMAGE'
      body[:image] = { media_id: payload }
    else
      body[:message_type] = 'TEXT'
      body[:text] = { body: payload }
    end

    response = HTTParty.post(endpoint, body: body.to_json, headers: headers)
    json = process_json_response(response, 'Failed to send TikTok message')

    json['data']['message']['message_id']
  end

  def upload_media(blob, media_type = 'IMAGE')
    endpoint = "#{api_base_url}/business/message/media/upload/"
    uri = URI.parse(endpoint)

    blob.open do |temp_file|
      temp_file.rewind
      body = {
        business_id: business_id,
        media_type: media_type,
        file: UploadIO.new(temp_file, blob.content_type || 'application/octet-stream', blob.filename.to_s)
      }

      request = Net::HTTP::Post::Multipart.new(uri.request_uri, body, { 'Access-Token' => access_token })
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
      json = process_json_response(response, 'Failed to upload TikTok media')
      json['data']['media_id']
    end
  end

  def api_base_url
    "https://business-api.tiktok.com/open_api/#{GlobalConfigService.load('TIKTOK_API_VERSION', 'v1.3')}"
  end

  def process_json_response(response, error_prefix)
    success = response.respond_to?(:success?) ? response.success? : response.is_a?(Net::HTTPSuccess)
    unless success
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{response.code}: #{response.body}"
    end

    res = JSON.parse(response.body)
    raise "#{res['code']}: #{res['message']}" if res['code'] != 0

    res
  end
end
