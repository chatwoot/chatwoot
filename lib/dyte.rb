class Dyte
  BASE_URL = 'https://api.cloudflare.com/client/v4'.freeze
  API_KEY_HEADER = 'Authorization'.freeze
  PRESET_NAME = 'group-call-host'.freeze

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
    response = post(path, payload)
    process_response(response)
  end

  private

  def process_response(response)
    return response.parsed_response['data'].with_indifferent_access if response.success?

    { error: response.parsed_response, error_code: response.code }
  end

  def post(path, payload)
    HTTParty.post(
      "#{BASE_URL}/accounts/#{@account_id}/realtime/kit/#{@app_id}/#{path}", {
        headers: { API_KEY_HEADER => "Bearer #{@api_token}", 'Content-Type' => 'application/json' },
        body: payload.to_json
      }
    )
  end
end
