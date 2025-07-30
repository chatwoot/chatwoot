module Captain::Loggable
  private

  def log_captain_activity(event_type, log_data = {})
    return if ENV['CAPTAIN_ENHANCED_LOGGING'].blank?

    conversation_id = log_data[:conversation_id]
    prefix = conversation_id ? "[##{conversation_id}]" : ''

    # Add timestamp to all log data
    log_data[:timestamp] = Time.current.iso8601

    Rails.logger.info "[CAPTAIN_DEBUG] #{prefix} [#{event_type}] #{JSON.pretty_generate(log_data)}"
  end

  def log_captain_request(tools, temperature)
    log_captain_activity(Llm::BaseOpenAiService::REQUEST, {
                           conversation_id: @conversation&.id,
                           assistant_id: @assistant&.id,
                           model: @model,
                           temperature: temperature,
                           messages_count: @messages.size,
                           tools_count: tools.size,
                           last_message: @messages.last
                         })
  end

  def log_captain_response(response, duration_ms)
    log_captain_activity(Llm::BaseOpenAiService::RESPONSE, {
                           conversation_id: @conversation&.id,
                           duration_ms: duration_ms,
                           response: response.dig('choices', 0, 'message'),
                           usage: response['usage']
                         })
  end

  def log_captain_error(error)
    log_captain_activity(Llm::BaseOpenAiService::ERROR, {
                           conversation_id: @conversation&.id,
                           error_class: error.class.name,
                           error_message: error.message,
                           context: { model: @model, assistant_id: @assistant&.id }
                         })
  end

  def log_captain_tool_call(function_name, arguments, result)
    log_captain_activity(Llm::BaseOpenAiService::TOOL_CALL, {
                           conversation_id: @conversation&.id,
                           tool_name: function_name,
                           arguments: arguments,
                           result: result.to_s.truncate(1000)
                         })
  end
end
