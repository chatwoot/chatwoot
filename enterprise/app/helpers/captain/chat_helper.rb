module Captain::ChatHelper
  def request_chat_completion
    Rails.logger.debug { "[CAPTAIN][ChatCompletion] #{@messages}" }

    response = @client.chat(
      parameters: {
        model: @model,
        messages: @messages,
        tools: @tool_registry&.registered_tools || [],
        response_format: { type: 'json_object' }
      }
    )

    handle_response(response)
  end

  def handle_response(response)
    Rails.logger.debug { "[CAPTAIN][ChatCompletion] #{response}" }
    message = response.dig('choices', 0, 'message')
    if message['tool_calls']
      process_tool_calls(message['tool_calls'])
    else
      JSON.parse(message['content'].strip)
    end
  end

  def process_tool_calls(tool_calls)
    append_tool_calls(tool_calls)
    tool_calls.each do |tool_call|
      process_tool_call(tool_call)
    end
    request_chat_completion
  end

  def process_tool_call(tool_call)
    arguments = JSON.parse(tool_call['function']['arguments'])
    function_name = tool_call['function']['name']
    tool_call_id = tool_call['id']

    if @tool_registry.respond_to?(function_name)
      execute_tool(function_name, arguments, tool_call_id)
    else
      process_invalid_tool_call(tool_call_id)
    end
  end

  def execute_tool(function_name, arguments, tool_call_id)
    result = @tool_registry.send(function_name, arguments)
    append_tool_response(result, tool_call_id)
  end

  def append_tool_calls(tool_calls)
    @messages << {
      role: 'assistant',
      tool_calls: tool_calls
    }
  end

  def process_invalid_tool_call(tool_call_id)
    append_tool_response('Tool not available', tool_call_id)
  end

  def append_tool_response(content, tool_call_id)
    @messages << {
      role: 'tool',
      tool_call_id: tool_call_id,
      content: content
    }
  end
end
