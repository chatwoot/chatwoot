module Captain::ChatHelper
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
        model: @model,
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
    formatted_response = "
    Question: #{response.question}
    Answer: #{response.answer}
    "
    if response.documentable.present? && response.documentable.try(:external_link)
      formatted_response += "
      Source: #{response.documentable.external_link}
      "
    end

    formatted_response
  end

  def append_tool_response(sections)
    @messages << {
      role: 'assistant',
      content: "Found the following FAQs in the documentation:\n #{sections}"
    }
  end
end
