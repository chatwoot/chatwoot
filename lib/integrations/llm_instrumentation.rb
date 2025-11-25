# frozen_string_literal: true

require 'opentelemetry_config'

module Integrations::LlmInstrumentation
  # OpenTelemetry attribute names following GenAI semantic conventions
  # https://opentelemetry.io/docs/specs/semconv/gen-ai/
  ATTR_GEN_AI_PROVIDER = 'gen_ai.provider.name'
  ATTR_GEN_AI_REQUEST_MODEL = 'gen_ai.request.model'
  ATTR_GEN_AI_REQUEST_TEMPERATURE = 'gen_ai.request.temperature'
  ATTR_GEN_AI_PROMPT_ROLE = 'gen_ai.prompt.%d.role'
  ATTR_GEN_AI_PROMPT_CONTENT = 'gen_ai.prompt.%d.content'
  ATTR_GEN_AI_COMPLETION_ROLE = 'gen_ai.completion.0.role'
  ATTR_GEN_AI_COMPLETION_CONTENT = 'gen_ai.completion.0.content'
  ATTR_GEN_AI_USAGE_INPUT_TOKENS = 'gen_ai.usage.input_tokens'
  ATTR_GEN_AI_USAGE_OUTPUT_TOKENS = 'gen_ai.usage.output_tokens'
  ATTR_GEN_AI_USAGE_TOTAL_TOKENS = 'gen_ai.usage.total_tokens'
  ATTR_GEN_AI_RESPONSE_ERROR = 'gen_ai.response.error'
  ATTR_GEN_AI_RESPONSE_ERROR_CODE = 'gen_ai.response.error_code'

  TOOL_SPAN_NAME = 'tool.%s'

  # Langfuse-specific attributes
  # https://langfuse.com/integrations/native/opentelemetry#property-mapping
  ATTR_LANGFUSE_USER_ID = 'langfuse.user.id'
  ATTR_LANGFUSE_SESSION_ID = 'langfuse.session.id'
  ATTR_LANGFUSE_TAGS = 'langfuse.trace.tags'
  ATTR_LANGFUSE_METADATA = 'langfuse.trace.metadata.%s'
  ATTR_LANGFUSE_TRACE_INPUT = 'langfuse.trace.input'
  ATTR_LANGFUSE_TRACE_OUTPUT = 'langfuse.trace.output'
  ATTR_LANGFUSE_OBSERVATION_INPUT = 'langfuse.observation.input'
  ATTR_LANGFUSE_OBSERVATION_OUTPUT = 'langfuse.observation.output'

  def tracer
    @tracer ||= OpentelemetryConfig.tracer
  end

  def instrument_llm_call(params)
    return yield unless ChatwootApp.otel_enabled?

    tracer.in_span(params[:span_name]) do |span|
      setup_span_attributes(span, params)
      result = yield
      record_completion(span, result)
      result
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: params[:account]).capture_exception
    yield
  end

  def instrument_agent_session(params)
    return yield unless ChatwootApp.otel_enabled?

    tracer.in_span(params[:span_name]) do |span|
      set_metadata_attributes(span, params)
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:messages].to_json)
      result = yield
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)

      result
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: params[:account]).capture_exception
    yield
  end

  def instrument_tool_call(tool_name, arguments)
    return yield unless ChatwootApp.otel_enabled?

    tracer.in_span(format(TOOL_SPAN_NAME, tool_name)) do |span|
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, arguments.to_json)
      result = yield
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
      result
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    yield
  end

  private

  def setup_span_attributes(span, params)
    set_request_attributes(span, params)
    set_prompt_messages(span, params[:messages])
    set_metadata_attributes(span, params)
  end

  def record_completion(span, result)
    set_completion_attributes(span, result) if result.is_a?(Hash)
  end

  def set_request_attributes(span, params)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openai')
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model])
    span.set_attribute(ATTR_GEN_AI_REQUEST_TEMPERATURE, params[:temperature]) if params[:temperature]
  end

  def set_prompt_messages(span, messages)
    messages.each_with_index do |msg, idx|
      role = msg[:role] || msg['role']
      content = msg[:content] || msg['content']

      span.set_attribute(format(ATTR_GEN_AI_PROMPT_ROLE, idx), role)
      span.set_attribute(format(ATTR_GEN_AI_PROMPT_CONTENT, idx), content.to_s)
    end
  end

  def set_metadata_attributes(span, params)
    session_id = params[:conversation_id].present? ? "#{params[:account_id]}_#{params[:conversation_id]}" : nil
    span.set_attribute(ATTR_LANGFUSE_USER_ID, params[:account_id].to_s) if params[:account_id]
    span.set_attribute(ATTR_LANGFUSE_SESSION_ID, session_id) if session_id.present?
    span.set_attribute(ATTR_LANGFUSE_TAGS, [params[:feature_name]].to_json)

    return unless params[:metadata].is_a?(Hash)

    params[:metadata].each do |key, value|
      span.set_attribute(format(ATTR_LANGFUSE_METADATA, key), value.to_s)
    end
  end

  def set_completion_attributes(span, result)
    set_completion_message(span, result)
    set_usage_metrics(span, result)
    set_error_attributes(span, result)
  end

  def set_completion_message(span, result)
    message = result[:message] || result.dig('choices', 0, 'message', 'content')
    return if message.blank?

    span.set_attribute(ATTR_GEN_AI_COMPLETION_ROLE, 'assistant')
    span.set_attribute(ATTR_GEN_AI_COMPLETION_CONTENT, message)
  end

  def set_usage_metrics(span, result)
    usage = result[:usage] || result['usage']
    return if usage.blank?

    span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, usage['prompt_tokens']) if usage['prompt_tokens']
    span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, usage['completion_tokens']) if usage['completion_tokens']
    span.set_attribute(ATTR_GEN_AI_USAGE_TOTAL_TOKENS, usage['total_tokens']) if usage['total_tokens']
  end

  def set_error_attributes(span, result)
    error = result[:error] || result['error']
    return if error.blank?

    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR, error.to_json)
    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR_CODE, error['error_code']) if error['error_code']
    span.status = OpenTelemetry::Trace::Status.error("API Error: #{error['error_code']}")
  end
end
