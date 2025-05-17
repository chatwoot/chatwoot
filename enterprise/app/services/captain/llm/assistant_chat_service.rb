require 'openai'

class Captain::Llm::AssistantChatService < Llm::BaseOpenAiService
  include Captain::ChatHelper

  def initialize(assistant: nil)
    super()

    @assistant = assistant
    @messages = [system_message]
    @response = ''
  end

  def generate_response(input, previous_messages = [], role = 'user')
    @messages += previous_messages
    @messages << { role: role, content: input } if input.present?
    request_chat_completion
  end

  private

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(@assistant.name, @assistant.config['product_name'], @assistant.config)
    }
  end
end
