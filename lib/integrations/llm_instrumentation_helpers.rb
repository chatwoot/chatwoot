# frozen_string_literal: true

module Integrations::LlmInstrumentationHelpers
  include Integrations::LlmInstrumentationConstants

  private

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

    error_code = result[:error_code] || result['error_code']
    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR, error.to_json)
    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR_CODE, error_code) if error_code
    span.status = OpenTelemetry::Trace::Status.error("API Error: #{error_code}")
  end
end
