module Captain::ToolInstrumentation
  extend ActiveSupport::Concern
  include Integrations::LlmInstrumentationConstants

  private

  # Custom instrumentation for tool flows - outputs just the message (not full hash)
  def instrument_tool_session(params)
    return yield unless ChatwootApp.otel_enabled?

    response = nil
    executed = false
    tracer.in_span(params[:span_name]) do |span|
      set_tool_session_attributes(span, params)
      response = yield
      executed = true
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, response[:message] || response.to_json)
      set_tool_session_error_attributes(span, response) if response.is_a?(Hash)
    end
    response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    executed ? response : yield
  end

  def set_tool_session_attributes(span, params)
    span.set_attribute(ATTR_LANGFUSE_USER_ID, params[:account_id].to_s) if params[:account_id]
    span.set_attribute(ATTR_LANGFUSE_SESSION_ID, "#{params[:account_id]}_#{params[:conversation_id]}") if params[:conversation_id].present?
    span.set_attribute(ATTR_LANGFUSE_TAGS, [params[:feature_name]].to_json)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:messages].to_json)
  end

  def set_tool_session_error_attributes(span, response)
    error = response[:error] || response['error']
    return if error.blank?

    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR, error.to_json)
    span.status = OpenTelemetry::Trace::Status.error(error.to_s.truncate(1000))
  end

  def record_generation(chat, message, model)
    return unless ChatwootApp.otel_enabled?
    return unless message.respond_to?(:role) && message.role.to_s == 'assistant'

    tracer.in_span("llm.#{event_name}.generation") do |span|
      span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openai')
      span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, model)
      span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, message.input_tokens)
      span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, message.output_tokens) if message.respond_to?(:output_tokens)
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, format_chat_messages(chat))
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, message.content.to_s) if message.respond_to?(:content)
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to record generation: #{e.message}"
  end

  def format_chat_messages(chat)
    chat.messages[0...-1].map { |m| { role: m.role.to_s, content: m.content.to_s } }.to_json
  end
end
