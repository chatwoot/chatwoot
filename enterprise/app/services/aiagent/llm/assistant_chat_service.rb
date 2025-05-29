require 'openai'

class Aiagent::Llm::AssistantChatService < Llm::BaseOpenAiService
  include Aiagent::ChatHelper

  def initialize(assistant: nil)
    super()

    @assistant = assistant
    @messages = [system_message]
    @response = ''
    register_tools
  end

  def generate_response(input, previous_messages = [], role = 'user')
    @messages += previous_messages
    @messages << { role: role, content: input } if input.present?
    request_chat_completion
  end

  private

  def register_tools
    @tool_registry = Aiagent::ToolRegistryService.new(@assistant)
    @tool_registry.register_tool(Aiagent::Tools::SearchDocumentationService)
  end

  def system_message
    {
      role: 'system',
      content: Aiagent::Llm::SystemPromptsService.assistant_response_generator(@assistant.name, @assistant.config['product_name'], @assistant.config)
    }
  end
end
