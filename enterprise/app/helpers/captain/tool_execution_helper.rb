module Captain::ToolExecutionHelper
  private

  def handle_response(response)
    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }
    message = response.dig('choices', 0, 'message')

    if message['tool_calls']
      process_tool_calls(message['tool_calls'])
    else
      message = JSON.parse(message['content'].strip)
      persist_message(message, 'assistant')
      message
    end
  end

  def process_tool_calls(tool_calls)
    append_tool_calls(tool_calls)
    tool_calls.each { |tool_call| process_tool_call(tool_call) }
    request_chat_completion
  end

  def process_tool_call(tool_call)
    arguments = JSON.parse(tool_call['function']['arguments'])
    function_name = tool_call['function']['name']
    tool_call_id = tool_call['id']

    if @tool_registry.respond_to?(function_name)
      execute_tool(function_name, arguments, tool_call_id)
    else
      process_invalid_tool_call(function_name, tool_call_id)
    end
  end

  def execute_tool(function_name, arguments, tool_call_id)
    persist_tool_status(function_name, 'captain.copilot.using_tool')
    result = perform_tool_call(function_name, arguments)
    persist_tool_status(function_name, 'captain.copilot.completed_tool_call')
    append_tool_response(result, tool_call_id)
  end

  def perform_tool_call(function_name, arguments)
    instrument_tool_call(function_name, arguments) do
      @tool_registry.send(function_name, arguments)
    end
  rescue StandardError => e
    Rails.logger.error "Tool #{function_name} failed: #{e.message}"
    "Error executing #{function_name}: #{e.message}"
  end

  def persist_tool_status(function_name, translation_key)
    persist_message(
      {
        content: I18n.t(translation_key, function_name: function_name),
        function_name: function_name
      },
      'assistant_thinking'
    )
  end

  def append_tool_calls(tool_calls)
    @messages << {
      role: 'assistant',
      tool_calls: tool_calls
    }
  end

  def process_invalid_tool_call(function_name, tool_call_id)
    persist_message(
      { content: I18n.t('captain.copilot.invalid_tool_call'), function_name: function_name },
      'assistant_thinking'
    )
    append_tool_response(I18n.t('captain.copilot.tool_not_available'), tool_call_id)
  end

  def append_tool_response(content, tool_call_id)
    @messages << {
      role: 'tool',
      tool_call_id: tool_call_id,
      content: content
    }
  end
end
