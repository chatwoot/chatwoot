require 'httparty'

class Captain::Llm::BaseJangkauService
  include HTTParty
  base_uri ENV.fetch('JANGKAU_AGENT_API_URL', 'https://agent.jangkau.ai/')

  def initialize(account_id, ai_agent, question, session_id, additional_attributes)
    @account_id = account_id
    @ai_agent = ai_agent
    @question = question
    @session_id = session_id
    @additional_attributes = additional_attributes
  end

  def perform
    generate_response
  end

  private

  def generate_response
    Rails.logger.info '[generate_response] Generating response for Jangkau AI Agent'

    # endpoint = feature_enabled_for_ai_agent? ? '/v2/chat/completion/' : '/v2/chat/override/'
    endpoint = '/v2/chat/completion/'

    response = self.class.post(
      endpoint,
      body: request_body.to_json,
      headers: headers
    )
    Rails.logger.info '[generate_response] Received Jangkau response'
    response
  rescue StandardError => e
    Rails.logger.error "[generate_response] error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  end

  def feature_enabled_for_ai_agent?
    enabled_ai_agents = ENV.fetch('FEATURE_FLAG_NEW_JANGKAU_ENDPOINT', '')
                           .split(',')
                           .map(&:strip)

    enabled_ai_agents.include?(@ai_agent.id.to_s)
  end

  def request_body
    {
      'question' => @question,
      'overrideConfig' => {
        'sessionId' => @session_id.to_s,
        'vars' => {
          'account_id' => @account_id.to_s,
          'customer_name' => @additional_attributes['name'] || '',
          'contact' => @additional_attributes['phone_number'] || '',
          'channel' => @additional_attributes['channel'] || ''
        }.merge(@ai_agent.flow_data || {})
      }
    }
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'X-API-Key' => ENV.fetch('JANGKAU_AGENT_API_KEY', nil)
    }
  end
end
