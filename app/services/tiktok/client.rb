require 'faraday'
require 'faraday/multipart'

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

  def image_send_capable?(conversation_id, conversation_type: 'SINGLE')
    endpoint = "#{api_base_url}/business/message/capabilities/get/"
    headers = { 'Access-Token': access_token }
    query = {
      business_id: business_id,
      conversation_id: conversation_id,
      conversation_type: conversation_type,
      capability_types: ['IMAGE_SEND'].to_json
    }

    response = HTTParty.get(endpoint, query: query, headers: headers)
    json = process_json_response(response, 'Failed to fetch TikTok message capabilities')
    capabilities = json.dig('data', 'capability_infos') || []
    image_send = capabilities.find { |capability| capability['capability_type'] == 'IMAGE_SEND' }

    image_send&.[]('capability_result') == true
  end

  def send_text_message(conversation_id, text, referenced_message_id: nil)
    send_message(conversation_id, 'TEXT', text, referenced_message_id: referenced_message_id)
  end

  def send_media_message(conversation_id, attachment)
    # As of now, only IMAGE media type is supported
    media_id = upload_media(attachment.file.blob, 'IMAGE')
    send_message(conversation_id, 'IMAGE', media_id)
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

    blob.open do |temp_file|
      temp_file.rewind
      payload = {
        business_id: business_id,
        media_type: media_type,
        file: Faraday::Multipart::FilePart.new(temp_file, blob.content_type || 'application/octet-stream', blob.filename.to_s)
      }

      response = multipart_connection.post(endpoint, payload) do |request|
        request.headers['Access-Token'] = access_token
      end
      json = process_json_response(response, 'Failed to upload TikTok media')
      json['data']['media_id']
    end
  end

  def multipart_connection
    @multipart_connection ||= Faraday.new do |faraday|
      faraday.request :multipart
    end
  end

  def api_base_url
    "https://business-api.tiktok.com/open_api/#{GlobalConfigService.load('TIKTOK_API_VERSION', 'v1.3')}"
  end

  def process_json_response(response, error_prefix)
    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response_status(response)}, Body: #{response.body}"
      raise "#{response_status(response)}: #{response.body}"
    end

    res = JSON.parse(response.body)
    raise "#{res['code']}: #{res['message']}" if res['code'] != 0

    res
  end

  def response_status(response)
    response.respond_to?(:code) ? response.code : response.status
  end
end
