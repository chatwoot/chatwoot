module Captain::Assistant::RunContextNormalizer
  private

  def build_run_context(result, response)
    {
      'messages' => normalized_run_messages(result.messages || []),
      'handoff_tool_called' => response['handoff_tool_called']
    }
  end

  def normalized_run_messages(messages)
    normalized_messages = messages.map { |message| normalize_run_message(message) }
    final_assistant_message = normalized_messages.reverse.find { |message| message['role'] == 'assistant' }
    strip_final_response(final_assistant_message) if final_assistant_message
    normalized_messages
  end

  def normalize_run_message(message)
    normalized = message.deep_stringify_keys
    normalized['role'] = normalized['role'].to_s if normalized['role'].present?
    normalized['content'] = normalized['content'].deep_stringify_keys if normalized['content'].is_a?(Hash)
    normalized
  end

  def strip_final_response(message)
    message['content'] = normalized_final_message_content(message['content'])
  end

  def normalized_final_message_content(content)
    return content.except('response') if content.is_a?(Hash)

    {}
  end
end
