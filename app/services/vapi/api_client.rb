class Vapi::ApiClient
  include HTTParty

  base_uri 'https://api.vapi.ai'

  def initialize
    @api_key = ENV.fetch('VAPI_API_KEY', nil)
    raise 'VAPI_API_KEY not configured' if @api_key.blank?

    @headers = {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json'
    }
  end

  def list_agents
    response = self.class.get('/assistant', headers: @headers)
    handle_response(response)
  end

  def get_agent(agent_id)
    response = self.class.get("/assistant/#{agent_id}", headers: @headers)
    handle_response(response)
  end

  def create_agent(agent_params)
    response = self.class.post('/assistant',
                               body: agent_params.to_json,
                               headers: @headers)
    handle_response(response)
  end

  def update_agent(agent_id, agent_params)
    response = self.class.patch("/assistant/#{agent_id}",
                                body: agent_params.to_json,
                                headers: @headers)
    handle_response(response)
  end

  def list_calls(params = {})
    response = self.class.get('/call',
                              query: params,
                              headers: @headers)
    handle_response(response)
  end

  def get_call(call_id)
    response = self.class.get("/call/#{call_id}", headers: @headers)
    handle_response(response)
  end

  private

  def handle_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 401
      raise 'Unauthorized: Check VAPI_API_KEY'
    when 404
      raise 'Resource not found'
    else
      Rails.logger.error "Vapi API Error: #{response.code} - #{response.body}"
      raise "Vapi API Error: #{response.code}"
    end
  end
end
