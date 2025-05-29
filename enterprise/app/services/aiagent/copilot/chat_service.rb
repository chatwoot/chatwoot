require 'openai'

class Aiagent::Copilot::ChatService < Llm::BaseOpenAiService
  include Aiagent::ChatHelper

  def initialize(topic, config)
    super()

    @topic = topic
    @conversation_history = config[:conversation_history]
    @previous_messages = config[:previous_messages] || []
    @language = config[:language] || 'english'

    register_tools
    @messages = [system_message, conversation_history_context] + @previous_messages
    @response = ''
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion
    Rails.logger.info("[AIAGENT][CopilotChatService] Incrementing response usage for #{@topic.account.id}")
    @topic.account.increment_response_usage

    response
  end

  private

  def register_tools
    @tool_registry = Aiagent::ToolRegistryService.new(@topic)
    @tool_registry.register_tool(Aiagent::Tools::SearchDocumentationService)
  end

  def system_message
    {
      role: 'system',
      content: Aiagent::Llm::SystemPromptsService.copilot_response_generator(@topic.config['product_name'], @language)
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
