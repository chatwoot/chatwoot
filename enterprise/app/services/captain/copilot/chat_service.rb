class Captain::Copilot::ChatService < Llm::BaseOpenAiService
  include Captain::ChatHelper

  attr_reader :assistant, :language

  def initialize(assistant, config = {})
    super()
    @assistant = assistant
    @tool_registry = Captain::ToolRegistryService.new(@assistant)
    @stream_writer = config[:stream_writer]
    setup_additional_info(config)
    register_tools
    @messages = build_initial_messages(config)
  end

  def setup_additional_info(config)
    additional_info = config[:additional_info] || {}
    @language = additional_info[:language] || 'english'
    @conversation_id = additional_info[:conversation_id]
    @contact_id = additional_info[:contact_id]
  end

  def register_tools
    @tool_registry.register_tool(Captain::Tools::Copilot::GetConversationService)
  end

  def build_initial_messages(config)
    messages = [system_message]
    messages += (config[:previous_messages] || [])
    messages << current_viewing_history if @conversation_id
    messages
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    Rails.logger.info("[CAPTAIN][CopilotChatService] Initial Prompt: #{@messages}")
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

  def current_viewing_history
    return unless @conversation_id

    {
      role: 'system',
      content: <<~HISTORY.strip
        You are currently viewing the conversation with the user with the following details:
        Conversation ID: #{@conversation_id}
        Contact ID: #{@contact_id}
        Account ID: #{@assistant.account.id}
      HISTORY
    }
  end
end
