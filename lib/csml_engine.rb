class CsmlEngine
  API_KEY_HEADER = 'X-Api-Key'.freeze

  def initialize
    @host_url = GlobalConfigService.load('CSML_BOT_HOST', '')
    @api_key = GlobalConfigService.load('CSML_BOT_API_KEY', '')

    raise ArgumentError, 'Missing Credentials' if @host_url.blank? || @api_key.blank?
  end

  def status
    response = HTTParty.get("#{@host_url}/status")
    process_response(response)
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
    response = post('run', payload)
    process_response(response)
  end

  def validate(bot)
    response = post('validate', bot)
    process_response(response)
  end

  private

  def process_response(response)
    return response.parsed_response if response.success?

    { error: response.parsed_response, status: response.code }
  end

  def post(path, payload)
    HTTParty.post(
      "#{@host_url}/#{path}", {
        headers: { API_KEY_HEADER => @api_key, 'Content-Type' => 'application/json' },
        body: payload.to_json
      }
    )
  end
end
