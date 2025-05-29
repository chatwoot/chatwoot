require 'openai'

class Aiagent::Llm::TopicChatService < Llm::BaseOpenAiService
  include Aiagent::ChatHelper

  def initialize(topic: nil)
    super()

    @topic = topic
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
    @tool_registry = Aiagent::ToolRegistryService.new(@topic)
    @tool_registry.register_tool(Aiagent::Tools::SearchDocumentationService)
  end

  def system_message
    {
      role: 'system',
      content: Aiagent::Llm::SystemPromptsService.topic_response_generator(@topic.name, @topic.config['product_name'], @topic.config)
    }
  end
end
