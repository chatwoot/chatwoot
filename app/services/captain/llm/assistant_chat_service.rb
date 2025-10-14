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
