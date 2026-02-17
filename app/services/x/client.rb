class X::Client
  include HTTParty
  base_uri 'https://api.x.com/2'

  attr_reader :bearer_token

  def initialize(bearer_token:)
    @bearer_token = bearer_token
  end

  def send_direct_message(participant_id:, text:, attachments: nil)
    body = { text: text }
    body[:attachments] = attachments if attachments

    post("/dm_conversations/with/#{participant_id}/messages", body: body)
  end

  def create_tweet(text:, reply_settings: nil, reply_to_tweet_id: nil, media_ids: nil)
    body = { text: text }
    body[:reply_settings] = reply_settings if reply_settings
    body[:reply] = { in_reply_to_tweet_id: reply_to_tweet_id } if reply_to_tweet_id
    body[:media] = { media_ids: media_ids } if media_ids&.any?

    post('/tweets', body: body)
  end

  def user(user_id)
    get("/users/#{user_id}", query: { 'user.fields' => 'profile_image_url,name,username' })
  end

  def me
    get('/users/me', query: { 'user.fields' => 'profile_image_url,name,username' })
  end

  UPLOAD_CHUNK_SIZE = 2_000_000 # 2MB per segment (~2.7MB base64)

  def upload_media(file, mime_type:, context: :dm)
    category = media_category_from_mime(mime_type, context)
    file_data = file.is_a?(String) ? file : file.read

    if chunked_upload_required?(mime_type)
      chunked_upload(file_data, mime_type, category)
    else
      simple_upload(file_data, mime_type, category)
    end
  end

  private

  # GIFs, videos, and audio require chunked upload (INIT → APPEND → FINALIZE)
  def chunked_upload_required?(mime_type)
    mime_type == 'image/gif' || mime_type.start_with?('video/') || mime_type.start_with?('audio/')
  end

  # One-shot JSON upload with base64 for standard images
  def simple_upload(file_data, mime_type, media_category)
    response = HTTParty.post(
      'https://api.x.com/2/media/upload',
      headers: auth_headers,
      body: { media: Base64.strict_encode64(file_data), media_category: media_category, media_type: mime_type }.to_json
    )
    data = handle_response(response)
    { 'media_id_string' => data.dig('data', 'id') }
  end

  # Chunked JSON upload with base64 segments for GIFs, videos, audio
  def chunked_upload(file_data, mime_type, media_category)
    media_id = media_upload_init(file_data.bytesize, mime_type, media_category)
    media_upload_append_chunks(media_id, file_data)
    finalize_data = media_upload_finalize(media_id)
    { 'media_id_string' => finalize_data.dig('data', 'id') }
  end

  def media_upload_init(file_size, mime_type, media_category)
    response = HTTParty.post(
      'https://api.x.com/2/media/upload/initialize',
      headers: auth_headers,
      body: { media_type: mime_type, total_bytes: file_size, media_category: media_category }.to_json
    )
    handle_response(response).dig('data', 'id')
  end

  def media_upload_append_chunks(media_id, file_data)
    offset = 0
    segment = 0
    while offset < file_data.bytesize
      chunk = file_data.byteslice(offset, UPLOAD_CHUNK_SIZE)
      response = HTTParty.post(
        "https://api.x.com/2/media/upload/#{media_id}/append",
        headers: auth_headers,
        body: { media: Base64.strict_encode64(chunk), segment_index: segment }.to_json,
        timeout: 120
      )
      handle_response(response)
      offset += UPLOAD_CHUNK_SIZE
      segment += 1
    end
  end

  def media_upload_finalize(media_id)
    response = HTTParty.post(
      "https://api.x.com/2/media/upload/#{media_id}/finalize",
      headers: auth_headers
    )
    handle_response(response)
  end

  def post(path, body:)
    response = self.class.post(
      path,
      headers: auth_headers,
      body: body.to_json
    )

    handle_response(response)
  end

  def get(path, query: {})
    response = self.class.get(
      path,
      headers: auth_headers,
      query: query
    )

    handle_response(response)
  end

  def auth_headers
    {
      'Authorization' => "Bearer #{bearer_token}",
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response)
    case response.code
    when 200..202
      parse_success_body(response)
    when 401
      raise X::Errors::UnauthorizedError, 'Token expired or invalid'
    when 429
      retry_after = response.headers['x-rate-limit-reset']
      raise X::Errors::RateLimitError, "Rate limit exceeded. Reset at: #{Time.zone.at(retry_after.to_i)}"
    else
      raise X::Errors::ApiError, "X API error (#{response.code}): #{extract_error_message(response)}"
    end
  end

  def parse_success_body(response)
    body = response.parsed_response
    return {} if body.nil? || (body.is_a?(String) && body.empty?)

    body.is_a?(String) ? JSON.parse(body) : body
  end

  def extract_error_message(response)
    parsed = response.parsed_response
    parsed = JSON.parse(parsed) if parsed.is_a?(String) && parsed.start_with?('{')
    parsed.is_a?(Hash) ? (parsed.dig('errors', 0, 'message') || parsed['detail']) : response.body
  end

  def media_category_from_mime(mime_type, context = :dm)
    prefix = context == :tweet ? 'tweet' : 'dm'

    return "#{prefix}_video" if mime_type.match?(%r{^video/})
    return "#{prefix}_gif" if mime_type == 'image/gif'

    "#{prefix}_image"
  end
end
