require 'httparty'

class Captain::Llm::AssistantChatService
  include HTTParty

  base_uri ENV.fetch('JANGKAU_AGENT_API_URL', 'https://agent.jangkau.ai/')

  def initialize(message, session_id, ai_agent, account_id)
    @message = message
    @session_id = session_id
    @ai_agent = ai_agent
    @account_id = account_id
  end

  def perform
    generate_response
  end

  def health
    Rails.logger.info "[health] Generating response for Jangkau AI Agent #{self.class.base_uri.strip}"
    response = self.class.get(
      '/v1/monitoring/health/',
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    )
    Rails.logger.info "[health] Received Jangkau response: #{response.code} #{response.body}"
    response
  rescue HTTParty::Error => e
    Rails.logger.error "[health] HTTParty error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[health] Standard error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  end

  private

  def generate_response
    question, additional_attributes = extract_message_data(@message)

    Rails.logger.info "Additional attributes: #{additional_attributes}"

    if @ai_agent.custom_agent?
      ::Captain::Llm::BaseFlowiseService.new(
        @account_id,
        @ai_agent,
        question,
        @session_id,
        additional_attributes
      ).perform
    else
      ::Captain::Llm::BaseJangkauService.new(
        @account_id,
        @ai_agent,
        question,
        @session_id,
        additional_attributes
      ).perform
    end
  end

  def extract_message_data(message)
    if message.is_a?(String)
      [message, {}]
    else
      [message.content, message.additional_attributes || {}]
    end
  end
end
