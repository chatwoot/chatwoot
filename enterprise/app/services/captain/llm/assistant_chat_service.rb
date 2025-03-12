require 'openai'

class Captain::Llm::AssistantChatService < Captain::Llm::BaseOpenAiService
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
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(@assistant.config['product_name'])
    }
  end

  def search_documentation_tool
    {
      type: 'function',
      function: {
        name: 'search_documentation',
        description: "Use this function to get documentation on functionalities you don't know about.",
        parameters: {
          type: 'object',
          properties: {
            search_query: {
              type: 'string',
              description: 'The search query to look up in the documentation.'
            }
          },
          required: ['search_query']
        }
      }
    }
  end

  def request_chat_completion
    response = @client.chat(
      parameters: {
        model: DEFAULT_MODEL,
        messages: @messages,
        tools: [search_documentation_tool],
        response_format: { type: 'json_object' }
      }
    )

    handle_response(response)
    @response
  end

  def handle_response(response)
    message = response.dig('choices', 0, 'message')

    if message['tool_calls']
      process_tool_calls(message['tool_calls'])
    else
      @response = JSON.parse(message['content'].strip)
    end
  end

  def process_tool_calls(tool_calls)
    process_tool_call(tool_calls.first)
  end

  def process_tool_call(tool_call)
    return unless tool_call['function']['name'] == 'search_documentation'

    query = JSON.parse(tool_call['function']['arguments'])['search_query']
    sections = fetch_documentation(query)
    append_tool_response(sections)
    request_chat_completion
  end

  def fetch_documentation(query)
    @assistant
      .responses
      .approved
      .search(query)
      .map { |response| format_response(response) }.join
  end

  def format_response(response)
    "\n\nQuestion: #{response[:question]}\nAnswer: #{response[:answer]}"
  end

  def append_tool_response(sections)
    @messages << {
      role: 'assistant',
      content: "Found the following FAQs in the documentation:\n #{sections}"
    }
  end
end
