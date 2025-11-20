# frozen_string_literal: true

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

  # Langfuse-specific attributes
  # https://langfuse.com/integrations/native/opentelemetry#property-mapping
  ATTR_LANGFUSE_USER_ID = 'langfuse.user.id'
  ATTR_LANGFUSE_SESSION_ID = 'langfuse.session.id'
  ATTR_LANGFUSE_TAGS = 'langfuse.trace.tags'

  def tracer
    @tracer ||= OpenTelemetry.tracer_provider.tracer('chatwoot')
  end

  def instrument_llm_call(params)
    return yield unless otel_enabled?

    tracer.in_span(params[:span_name]) do |span|
      begin
        set_request_attributes(span, params)
        set_prompt_messages(span, params[:messages])
        set_metadata_attributes(span, params)
      rescue StandardError => e
        Rails.logger.error("LLM instrumentation setup error: #{e.message}")
      end

      result = yield

      begin
        set_completion_attributes(span, result) if result.is_a?(Hash)
      rescue StandardError => e
        Rails.logger.error("LLM instrumentation completion error: #{e.message}")
      end

      result
    end
  end

  private

  def otel_enabled?
    ENV['OTEL_PROVIDER'].present?
  end

  def set_request_attributes(span, params)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openai')
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model])
    span.set_attribute(ATTR_GEN_AI_REQUEST_TEMPERATURE, params[:temperature]) if params[:temperature]
  end

  def set_prompt_messages(span, messages)
    messages.each_with_index do |msg, idx|
      span.set_attribute(format(ATTR_GEN_AI_PROMPT_ROLE, idx), msg['role'])
      span.set_attribute(format(ATTR_GEN_AI_PROMPT_CONTENT, idx), msg['content'])
    end
  end

  def set_metadata_attributes(span, params)
    span.set_attribute(ATTR_LANGFUSE_USER_ID, params[:account_id].to_s) if params[:account_id]
    span.set_attribute(ATTR_LANGFUSE_SESSION_ID, params[:conversation_id].to_s) if params[:conversation_id]
    span.set_attribute(ATTR_LANGFUSE_TAGS, [params[:feature_name]].to_json)
  end

  def set_completion_attributes(span, result)
    set_completion_message(span, result)
    set_usage_metrics(span, result)
    set_error_attributes(span, result)
  end

  def set_completion_message(span, result)
    return if result[:message].blank?

    span.set_attribute(ATTR_GEN_AI_COMPLETION_ROLE, 'assistant')
    span.set_attribute(ATTR_GEN_AI_COMPLETION_CONTENT, result[:message])
  end

  def set_usage_metrics(span, result)
    return if result[:usage].blank?

    usage = result[:usage]
    span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, usage['prompt_tokens']) if usage['prompt_tokens']
    span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, usage['completion_tokens']) if usage['completion_tokens']
    span.set_attribute(ATTR_GEN_AI_USAGE_TOTAL_TOKENS, usage['total_tokens']) if usage['total_tokens']
  end

  def set_error_attributes(span, result)
    return if result[:error].blank?

    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR, result[:error].to_json)
    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR_CODE, result[:error_code]) if result[:error_code]
    span.status = OpenTelemetry::Trace::Status.error("API Error: #{result[:error_code]}")
  end
end
