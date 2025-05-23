require 'openai'

class Captain::Copilot::ChatService < Llm::BaseOpenAiService
  include Captain::ChatHelper

  attr_reader :assistant, :account, :user, :copilot_thread, :previous_history, :messages

  def initialize(assistant, config)
    super()

    @assistant = assistant
    @account = assistant.account
    @user = nil
    @copilot_thread = nil
    @previous_history = []
    setup_user(config)
    setup_message_history(config)
    register_tools
    @messages = build_messages(config)
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion

    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Incrementing response usage for account #{@account.id}"
    )
    @account.increment_response_usage

    response
  end

  private

  def setup_user(config)
    @user = @account.users.find_by(id: config[:user_id]) if config[:user_id].present?
  end

  def build_messages(config)
    messages= [system_message]
    messages << account_id_context
    messages += @previous_history if @previous_history.present?
    messages += current_viewing_history(config[:conversation_id]) if config[:conversation_id].present?
    messages
  end

  def setup_message_history(config)
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Previous History: #{config[:previous_history]&.length || 0}, Language: #{config[:language]}"
    )

    @copilot_thread = @account.copilot_threads.find_by(id: config[:copilot_thread_id]) if config[:copilot_thread_id].present?
    @previous_history = if @copilot_thread.present?
                          @copilot_thread.previous_history
                        else
                          config[:previous_history].presence || []
                        end
  end

  def register_tools
    @tool_registry = Captain::ToolRegistryService.new(@assistant, user: @user)
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
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(@assistant.config['product_name'])
    }
  end

  def account_id_context
    {
      role: 'system',
      content: "The current account id is #{@account.id}. The account is using #{@account.locale_english_name} as the language."
    }
  end

  def current_viewing_history(conversation_id)
    conversation = @account.conversations.find_by(display_id: conversation_id)
    return [] unless conversation

    Rails.logger.info("#{self.class.name} Assistant: #{@assistant.id}, Setting viewing history for conversation_id=#{conversation_id}")
    contact_id = conversation.contact_id
    [{
      role: 'system',
      content: <<~HISTORY.strip
        You are currently viewing the conversation with the following details:
        Conversation ID: #{conversation_id}
        Contact ID: #{contact_id}
      HISTORY
    }]
  end

  def persist_message(message, message_type = 'assistant')
    return if @copilot_thread.blank?

    @copilot_thread.copilot_messages.create!(
      message: message,
      message_type: message_type
    )
  end
end
