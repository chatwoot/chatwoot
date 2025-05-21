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
    @user_id = additional_info[:user_id]
    Rails.logger.info("[Captain::Copilot::ChatService::User] user_id: #{@user_id}")
  end

  def build_initial_messages(config)
    Rails.logger.info("[CAPTAIN][CopilotChatService] Building initial messages for conversation_id=#{@conversation_id}")
    messages = [system_message]
    messages += (config[:previous_messages] || [])
    Rails.logger.info("[CAPTAIN][CopilotChatService] Added #{config[:previous_messages]&.length || 0} previous messages")
    messages << current_viewing_history if @conversation_id
    Rails.logger.info("[CAPTAIN][CopilotChatService] Total messages built: #{messages.length}")
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

  def register_tools
    @tool_registry = Captain::ToolRegistryService.new(@assistant)
    @tool_registry.register_tool(Captain::Tools::SearchDocumentationService)
    @tool_registry.register_tool(Captain::Tools::Copilot::GetArticleService)
    @tool_registry.register_tool(Captain::Tools::Copilot::GetContactService)
    @tool_registry.register_tool(Captain::Tools::Copilot::GetConversationService)
    @tool_registry.register_tool(Captain::Tools::Copilot::SearchArticlesService)
    @tool_registry.register_tool(Captain::Tools::Copilot::SearchContactsService)
    @tool_registry.register_tool(Captain::Tools::Copilot::SearchConversationsService)
    @tool_registry.register_tool(Captain::Tools::Copilot::SearchLinearIssuesService)
  end

  def system_message
    Rails.logger.info("[CAPTAIN][CopilotChatService] Generating system message for product=#{@assistant.config['product_name']} language=#{@language}")
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(@assistant.config['product_name'], @language, @assistant.account_id)
    }
  end

  def current_viewing_history
    Rails.logger.info("[CAPTAIN][CopilotChatService] Fetching viewing history for conversation_id=#{@conversation_id}")
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
