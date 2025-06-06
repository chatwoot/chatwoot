require 'openai'

class Captain::Copilot::ChatService < Llm::BaseOpenAiService
  include Captain::ChatHelper

  def initialize(assistant, config)
    super()

    @assistant = assistant
    @conversation_history = config[:conversation_history]
    @previous_messages = config[:previous_messages] || []
    @language = config[:language] || 'english'
    @messages = [system_message, conversation_history_context] + @previous_messages
    @response = ''
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion
    Rails.logger.info("[CAPTAIN][CopilotChatService] Incrementing response usage for #{@assistant.account.id}")
    @assistant.account.increment_response_usage

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
    {
      role: 'system',
      content: "
      Message History with the user is below:
      #{@conversation_history}
      "
    }
  end
end
