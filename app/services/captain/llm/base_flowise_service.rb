require 'httparty'

class Captain::Llm::BaseFlowiseService
  include HTTParty
  base_uri ENV.fetch('FLOWISE_API_URL', 'https://ai.radyalabs.id/api/v1')

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
    Rails.logger.info '[generate_response] Generating response for Flowise AI Agent'
    response = self.class.post(
      "/prediction/#{@ai_agent.chat_flow_id}",
      body: request_body.to_json,
      headers: headers
    )
    Rails.logger.info "[generate_response] Received Flowise response: #{response.code} #{response.body}"
    response
  rescue HTTParty::Error => e
    Rails.logger.error "[generate_response] HTTParty error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[generate_response] Standard error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  end

  def request_body
    {
      'question' => @question,
      'overrideConfig' => {
        'sessionId' => @session_id,
        'vars' => {
          'account_id' => @account_id,
          'table_name' => ENV.fetch('SUPABASE_TABLE_NAME', 'reservasi_klinik')
        }
      }
    }
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('FLOWISE_API_KEY', nil)}"
    }
  end
end
