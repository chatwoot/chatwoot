class Dyte
  BASE_URL = 'https://api.cloudflare.com/client/v4'.freeze
  API_KEY_HEADER = 'Authorization'.freeze
  PRESET_NAME = 'group-call-host'.freeze
  LEGACY_PRESET_NAME = 'group_call_host'.freeze

  def initialize(account_id = nil, app_id = nil, api_token = nil)
    @account_id = account_id
    @app_id = app_id
    @api_token = api_token

    raise ArgumentError, 'Missing Credentials' if @account_id.blank? || @app_id.blank? || @api_token.blank?
  end

  def create_a_meeting(title)
    payload = {
      'title': title
    }
    path = 'meetings'
    response = post(path, payload)
    process_response(response)
  end

  def add_participant_to_meeting(meeting_id, client_id, name, avatar_url)
    raise ArgumentError, 'Missing information' if meeting_id.blank? || client_id.blank? || name.blank? || avatar_url.blank?

    payload = {
      'custom_participant_id': client_id.to_s,
      'name': name,
      'picture': avatar_url,
      'preset_name': PRESET_NAME
    }
    path = "meetings/#{meeting_id}/participants"
    response = process_response(post(path, payload))
    return response unless preset_not_found?(response)

    payload[:preset_name] = LEGACY_PRESET_NAME
    process_response(post(path, payload))
  end

  def refresh_participant_token(meeting_id, participant_id)
    raise ArgumentError, 'Missing information' if meeting_id.blank? || participant_id.blank?

    path = "meetings/#{meeting_id}/participants/#{participant_id}/token"
    response = post(path)
    process_response(response)
  end

  def fetch_participants(meeting_id)
    raise ArgumentError, 'Missing information' if meeting_id.blank?

    response = get("meetings/#{meeting_id}/participants")
    process_response(response)
  end

  private

  def process_response(response)
    return { error: response.parsed_response, error_code: response.code } unless response.success?

    data = parsed_data(response)
    return data.with_indifferent_access if data.is_a?(Hash)
    return data.map(&:with_indifferent_access) if data.is_a?(Array)

    { error: :unexpected_response, error_code: response.code }
  end

  def parsed_data(response)
    response.parsed_response['data']
  end

  def preset_not_found?(response)
    error = response[:error]
    message = error.dig('error', 'message') if error.is_a?(Hash) && error['error'].is_a?(Hash)
    message ||= error['message'] if error.is_a?(Hash)
    message ||= error.to_s
    message.include?('No preset found')
  end

  def post(path, payload = nil)
    HTTParty.post(
      "#{BASE_URL}/accounts/#{@account_id}/realtime/kit/#{@app_id}/#{path}", {
        headers: { API_KEY_HEADER => "Bearer #{@api_token}", 'Content-Type' => 'application/json' },
        body: payload&.to_json
      }.compact
    )
  end

  def get(path)
    HTTParty.get(
      "#{BASE_URL}/accounts/#{@account_id}/realtime/kit/#{@app_id}/#{path}",
      headers: { API_KEY_HEADER => "Bearer #{@api_token}", 'Content-Type' => 'application/json' }
    )
  end
end
