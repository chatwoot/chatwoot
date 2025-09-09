class Captain::Llm::AssistantChatService
  def initialize(question, session_id, ai_agent, account_id)
    @question = question
    @session_id = session_id
    @ai_agent = ai_agent
    @account_id = account_id
  end

  def perform
    generate_response
  end

  private

  def generate_response
    ::Captain::Llm::BaseJangkauService.new(@account_id, @ai_agent, @question, @session_id).perform
  end

  # def generate_response
  #   if @ai_agent.flowise?
  #     ::Captain::Llm::BaseFlowiseService.new(@account_id, @ai_agent, @question, @session_id).perform
  #   elsif @ai_agent.jangkau?
  #     ::Captain::Llm::BaseJangkauService.new(@account_id, @ai_agent, @question, @session_id).perform
  #   else
  #     raise "Unsupported AI Agent type: #{@ai_agent.template_type}"
  #   end
  # end
end
