class Captain::Copilot::ChatService < Llm::BaseOpenAiService
  include Captain::ChatHelper

  attr_reader :assistant, :language

  def initialize(assistant, config = {})
    super()
    @assistant = assistant
    @tool_registry = Captain::ToolRegistryService.new(@assistant)
    @language = config[:language] || 'english'
    @messages = build_initial_messages(config)
    @stream_writer = config[:stream_writer]
  end

  def build_initial_messages(config)
    messages = [system_message]
    messages << conversation_history_context if config[:conversation_history].present?
    messages + (config[:previous_messages] || [])
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion
    Rails.logger.info("[CAPTAIN][CopilotChatService] Incrementing response usage for #{@assistant.account.id}")
    @assistant.account.increment_response_usage

    publish_to_stream(
      {
        response: response,
        type: 'final_response'
      }
    )
    response
  end

  private

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(@assistant.config['product_name'], @language)
    }
  end

  def conversation_history_context
    return if @conversation_history.blank?

    {
      role: 'system',
      content: <<~HISTORY.strip
        Message History with the user is below:
        #{@conversation_history}
      HISTORY
    }
  end
end
