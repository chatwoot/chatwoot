class Tiktok::Client
  # Always use Tiktok::TokenService to get a valid access token
  pattr_initialize [:business_id!, :access_token!]

  def business_account_details
    endpoint = 'https://business-api.tiktok.com/open_api/v1.3/business/get/'
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
    endpoint = 'https://business-api.tiktok.com/open_api/v1.3/business/message/media/download/'
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
    media_id = upload_media(attachment.file, 'IMAGE')
    send_message(conversation_id, 'IMAGE', media_id, referenced_message_id: referenced_message_id)
  end

  private

  def send_message(conversation_id, type, payload, referenced_message_id: nil)
    # https://business-api.tiktok.com/portal/docs?id=1832184403754242
    endpoint ='https://business-api.tiktok.com/open_api/v1.3/business/message/send/'
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

  def upload_media(file, media_type = 'IMAGE')
    # Using Faraday for multipart upload as HTTParty doesn't handle file uploads correctly
    # See: https://github.com/jnunemaker/httparty/issues/600
    require 'faraday'
    require 'faraday/multipart'

    file.open do |temp_file|
      response = upload_media_with_faraday(temp_file, media_type)
      json = process_json_response(wrap_faraday_response(response), 'Failed to upload TikTok media')
      json['data']['media_id']
    end
  end

  def upload_media_with_faraday(temp_file, media_type)
    conn = Faraday.new do |f|
      f.request :multipart
      f.adapter Faraday.default_adapter
    end
    endpoint = 'https://business-api.tiktok.com/open_api/v1.3/business/message/media/upload/'
    payload = { business_id: business_id, media_type: media_type, file: Faraday::Multipart::FilePart.new(temp_file.path, 'image/jpeg') }
    conn.post(endpoint) do |req|
      req.headers['Access-Token'] = access_token
      req.body = payload
    end
  end

  def wrap_faraday_response(response)
    OpenStruct.new(success?: response.success?, code: response.status, body: response.body)
  end

  def process_json_response(response, error_prefix)
    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{response.code}: #{response.body}"
    end

    res = JSON.parse(response.body)
    raise "#{res['code']}: #{res['message']}" if res['code'] != 0

    res
  end
end
