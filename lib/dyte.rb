class Dyte
  BASE_URL = 'https://api.dyte.io/v2'.freeze
  API_KEY_HEADER = 'Authorization'.freeze
  PRESET_NAME = 'group_call_host'.freeze

  def initialize(organization_id, api_key)
    @api_key = Base64.strict_encode64("#{organization_id}:#{api_key}")
    @organization_id = organization_id

    raise ArgumentError, 'Missing Credentials' if @api_key.blank? || @organization_id.blank?
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
      "#{BASE_URL}/#{path}", {
        headers: { API_KEY_HEADER => "Basic #{@api_key}", 'Content-Type' => 'application/json' },
        body: payload.to_json
      }
    )
  end
end
