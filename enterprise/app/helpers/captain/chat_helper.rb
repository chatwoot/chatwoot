module Captain::ChatHelper
  def request_chat_completion
    log_chat_completion_request

    chat = RubyLLM.chat(model: @model)
    chat.with_temperature(@assistant&.config&.[]('temperature').to_f || 1)

    @tools&.each do |tool|
      chat.with_tool(tool)
    end

    chat.on_tool_call do |tool_call|
      persist_thinking_message(tool_call)
    end

    system_msg = @messages.find { |m| m[:role] == 'system' || m[:role] == :system }
    chat.with_instructions(system_msg[:content]) if system_msg

    conversation_messages = @messages.reject { |m| m[:role] == 'system' || m[:role] == :system }
    conversation_messages[0...-1].each do |msg|
      chat.add_message(role: msg[:role].to_sym, content: msg[:content])
    end

    last_message = conversation_messages.last
    response = chat.ask(last_message[:content])

    build_response(response)
  end

  private

  def persist_thinking_message(tool_call)
    return unless defined?(@copilot_thread) && @copilot_thread.present?

    tool_name = tool_call.name.to_s

    persist_message(
      {
        'content' => "Using #{tool_name}",
        'function_name' => tool_name
      },
      'assistant_thinking'
    )
  end

  def build_response(response)
    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }

    parsed = parse_json_response(response.content)

    persist_message(parsed, 'assistant')
    { 'response' => parsed }
  end

  def parse_json_response(content)
    content = content.gsub('```json', '').gsub('```', '')
    content = content.strip
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error parsing JSON response: #{e.message}"
    { 'content' => content }
  end

  def log_chat_completion_request
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Requesting chat completion
      for messages #{@messages} with #{@tools&.length || 0} tools
      "
    )
  end
end
