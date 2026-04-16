module Captain::ChatResponseHelper
  include Integrations::LlmInstrumentationConstants

  private

  def build_response(response)
    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }

    parsed = parse_json_response(response.content)
    apply_credit_usage_metadata(parsed)

    persist_message(parsed, 'assistant')
    parsed
  end

  def parse_json_response(content)
    content = content.gsub('```json', '').gsub('```', '')
    content = content.strip
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error parsing JSON response: #{e.message}"
    { 'content' => content }
  end

  def apply_credit_usage_metadata(parsed_response)
    return unless captain_v1_assistant?

    OpenTelemetry::Trace.current_span.set_attribute(
      format(ATTR_LANGFUSE_METADATA, 'credit_used'),
      credit_used_for_response?(parsed_response).to_s
    )
  rescue StandardError => e
    Rails.logger.warn "#{self.class.name} Assistant: #{@assistant.id}, Failed to set credit usage metadata: #{e.message}"
  end

  def credit_used_for_response?(parsed_response)
    response = parsed_response['response']
    response.present? && response != 'conversation_handoff'
  end

  def captain_v1_assistant?
    feature_name == 'assistant' && !@assistant.account.feature_enabled?('captain_integration_v2')
  end

  def persist_thinking_message(tool_call)
    return if @copilot_thread.blank?

    tool_name = tool_call.name.to_s

    persist_message(
      {
        'content' => "Using #{tool_name}",
        'function_name' => tool_name
      },
      'assistant_thinking'
    )
  end

  def persist_tool_completion
    return if @copilot_thread.blank?

    tool_call = @pending_tool_calls&.pop
    return unless tool_call

    tool_name = tool_call.name.to_s

    persist_message(
      {
        'content' => "Completed #{tool_name}",
        'function_name' => tool_name
      },
      'assistant_thinking'
    )
  end
end
