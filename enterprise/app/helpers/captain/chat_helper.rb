module Captain::ChatHelper
  def request_chat_completion
    CaptainTracer.in_span('llm_chat_completion') do |span|
      # span.set_attribute('model', @model)
      # span.set_attribute('messages', @messages)
      # span.set_attribute('tools', @tool_registry&.registered_tools || [])
      span.set_attribute('input', @messages.last[:content])
      span.set_attribute('temperature', @assistant&.config&.[]('temperature').to_f || 1)

      log_chat_completion_request

      response = @client.chat(
        parameters: {
          model: @model,
          messages: @messages,
          tools: @tool_registry&.registered_tools || [],
          response_format: { type: 'json_object' },
          temperature: @assistant&.config&.[]('temperature').to_f || 1
        }
      )

      span.set_attribute('model', response['model'])
      span.set_attribute('llm.usage.cached_tokens', response.dig('usage', 'prompt_tokens_details', 'cached_tokens'))
      # span.set_attribute('llm.usage.input_tokens', response.dig('usage', 'input_tokens'))
      span.set_attribute('llm.usage.output_tokens', response.dig('usage', 'output_tokens'))
      span.set_attribute('llm.usage.total_tokens', response.dig('usage', 'total_tokens'))
      span.set_attribute('llm.usage.completion_tokens', response.dig('usage', 'completion_tokens'))
      span.set_attribute('llm.completions.0.role', response['role'])
      span.set_attribute('llm.completions.0.content', response['content']&.first&.[]('text') || 'empty-response')

      handle_response(response)
    end
  rescue StandardError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error in chat completion: #{e}"
    raise e
  end

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
    tool_calls.each do |tool_call|
      process_tool_call(tool_call)
    end
    request_chat_completion
  end

  def process_tool_call(tool_call)
    CaptainTracer.in_span('llm_tool_call') do |span|
      arguments = JSON.parse(tool_call['function']['arguments'])
      function_name = tool_call['function']['name']
      tool_call_id = tool_call['id']
      span.set_attribute('function_name', function_name)
      if arguments.present?
        arguments.each do |key, value|
          span.set_attribute("arguments.#{key}", value)
        end
      end

      if @tool_registry.respond_to?(function_name)
        execute_tool(function_name, arguments, tool_call_id)
      else
        process_invalid_tool_call(function_name, tool_call_id)
      end
    end
  end

  def execute_tool(function_name, arguments, tool_call_id)
    persist_message(
      {
        content: I18n.t('captain.copilot.using_tool', function_name: function_name),
        function_name: function_name
      },
      'assistant_thinking'
    )
    result = @tool_registry.send(function_name, arguments)
    persist_message(
      {
        content: I18n.t('captain.copilot.completed_tool_call', function_name: function_name),
        function_name: function_name
      },
      'assistant_thinking'
    )
    append_tool_response(result, tool_call_id)
  end

  def append_tool_calls(tool_calls)
    @messages << {
      role: 'assistant',
      tool_calls: tool_calls
    }
  end

  def process_invalid_tool_call(function_name, tool_call_id)
    persist_message({ content: I18n.t('captain.copilot.invalid_tool_call'), function_name: function_name }, 'assistant_thinking')
    append_tool_response(I18n.t('captain.copilot.tool_not_available'), tool_call_id)
  end

  def append_tool_response(content, tool_call_id)
    @messages << {
      role: 'tool',
      tool_call_id: tool_call_id,
      content: content
    }
  end

  def log_chat_completion_request
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Requesting chat completion
      for messages #{@messages} with #{@tool_registry&.registered_tools&.length || 0} tools
      "
    )
  end
end
