class CsmlEngine
  API_KEY_HEADER = 'X-Api-Key'.freeze

  def initialize(host_url, api_key)
    @host_url = host_url
    @api_key = api_key
  end

  def status
    response = HTTParty.get("#{@host_url}/status")

    return response.parsed_response if response.success?

    { error: response.parsed_response, status: response.code }
  end

  def run(bot, params)
    payload = {
      bot: bot,
      event: {
        request_id: SecureRandom.uuid,
        client: params[:client],
        payload: params[:payload],
        metadata: params[:metadata],
        ttl_duration: 4000
      }
    }
    response = HTTParty.post(
      "#{@host_url}/run", {
        headers: { API_KEY_HEADER => @api_key, 'Content-Type' => 'application/json' },
        body: payload.to_json,
        debug_output: $stdout
      }
    )

    return response.parsed_response if response.success?

    { error: response.parsed_response, status: response.code }
  end

  def validate(bot)
    response = HTTParty.post(
      "#{@host_url}/validate", {
        headers: { API_KEY_HEADER => @api_key, 'Content-Type' => 'application/json' },
        body: bot.to_json,
        debug_output: $stdout
      }
    )

    return response.parsed_response if response.success?

    { error: response.parsed_response, status: response.code }
  end
end
