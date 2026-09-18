module Captain::Llm::AssistantResponseInspectionHelpers
  MAX_CONTEXT_MESSAGES = 10

  private

  def assistant_response_inspection_prompt(message_history:, assistant_response:, response_tag:)
    <<~PROMPT
      <account_custom_instructions>
      #{@assistant.config['instructions']}
      </account_custom_instructions>

      <conversation_context>
      #{format_conversation_context(message_history)}
      </conversation_context>

      <#{response_tag}>
      #{assistant_response}
      </#{response_tag}>
    PROMPT
  end

  def format_conversation_context(messages)
    normalize_messages(messages).last(MAX_CONTEXT_MESSAGES).filter_map do |message|
      content = message[:content].to_s.strip
      next if content.blank?

      "#{role_label(message[:role])}: #{content}"
    end.join("\n")
  end

  def normalize_messages(message_history)
    message_history.filter_map do |message|
      role = message[:role] || message['role']
      next if role.blank?

      { role: role.to_s, content: normalize_content(message[:content] || message['content']) }
    end
  end

  def normalize_content(content)
    return content if content.is_a?(String)
    return content.filter_map { |part| part[:text] || part['text'] if text_part?(part) }.join("\n") if content.is_a?(Array)

    content.to_s
  end

  def text_part?(part)
    return false unless part.is_a?(Hash)

    (part[:type] || part['type']).to_s == 'text'
  end

  def role_label(role)
    return 'User' if role == 'user'
    return 'Assistant' if role == 'assistant'

    role.to_s.titleize
  end

  def parse_response(content)
    return content if content.is_a?(Hash)

    JSON.parse(sanitize_json_response(content))
  rescue JSON::ParserError, TypeError
    {}
  end
end
