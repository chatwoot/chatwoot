module Captain::ChatHelper
  def request_chat_completion
    Rails.logger.debug { "[CAPTAIN][ChatCompletion] #{@messages}" }

    available_tools = @tool_registry&.registered_tools || []
    response = @client.chat(
      parameters: {
        model: @model,
        messages: @messages,
        tools: available_tools,
        response_format: { type: 'json_object' }
      }
    )

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error { "[CAPTAIN][ChatCompletion] #{e}" }
    raise e
  end

  def handle_response(response)
    Rails.logger.info { "[CAPTAIN][ChatCompletion] #{response}" }
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
    tool_call_id = tool_call['id']
    function_name = tool_call['function']['name']
    arguments = JSON.parse(tool_call['function']['arguments'])

    if @tool_registry.respond_to?(function_name)
      execute_tool_call(tool_call_id, function_name, arguments)
    else
      process_invalid_tool_call(tool_call_id, function_name)
    end
  end

  def append_tool_calls(tool_calls)
    @messages << {
      role: 'assistant',
      tool_calls: tool_calls
    }
  end

  def append_tool_response(content, tool_call_id)
    @messages << {
      role: 'tool',
      tool_call_id: tool_call_id,
      content: content
    }
  end

  def publish_to_stream(response)
    @stream_writer&.call(response)
  end

  def execute_tool_call(tool_call_id, function_name, arguments)
    publish_to_stream(
      {
        response: { response: "Processing tool call #{function_name}" },
        type: 'tool_calls_start'
      }
    )
    result = @tool_registry.send(function_name, arguments)
    append_tool_response(result, tool_call_id)
    publish_to_stream(
      {
        response: { response: "Received tool response #{function_name}" },
        type: 'tool_response',
        tool: function_name
      }
    )
  end

  def process_invalid_tool_call(tool_call_id, function_name)
    append_tool_response('Tool not implemented', tool_call_id)
    publish_to_stream(
      {
        response: { response: 'Tool not implemented' },
        type: 'tool_error',
        tool: function_name
      }
    )
  end
end
