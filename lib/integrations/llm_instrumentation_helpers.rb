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

    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR, error.to_json)
    span.status = OpenTelemetry::Trace::Status.error(error.to_s.truncate(1000))
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
end
