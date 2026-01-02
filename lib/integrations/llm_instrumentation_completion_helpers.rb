# frozen_string_literal: true

module Integrations::LlmInstrumentationCompletionHelpers
  include Integrations::LlmInstrumentationConstants

  private

  def set_embedding_span_attributes(span, params)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, determine_provider(params[:model]))
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model])
    span.set_attribute('embedding.input_length', params[:input]&.length || 0)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:input].to_s)
    set_common_span_metadata(span, params)
  end

  def set_audio_transcription_span_attributes(span, params)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openai')
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model] || 'whisper-1')
    span.set_attribute('audio.duration_seconds', params[:duration]) if params[:duration]
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:file_path].to_s) if params[:file_path]
    set_common_span_metadata(span, params)
  end

  def set_moderation_span_attributes(span, params)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openai')
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model] || 'text-moderation-latest')
    span.set_attribute('moderation.input_length', params[:input]&.length || 0)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:input].to_s)
    set_common_span_metadata(span, params)
  end

  def set_common_span_metadata(span, params)
    span.set_attribute(ATTR_LANGFUSE_USER_ID, params[:account_id].to_s) if params[:account_id]
    span.set_attribute(ATTR_LANGFUSE_TAGS, [params[:feature_name]].to_json) if params[:feature_name]
  end

  def set_embedding_result_attributes(span, result)
    span.set_attribute('embedding.dimensions', result&.length || 0) if result.is_a?(Array)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, "[#{result&.length || 0} dimensions]")
  end

  def set_transcription_result_attributes(span, result)
    transcribed_text = result.respond_to?(:text) ? result.text : result.to_s
    span.set_attribute('transcription.length', transcribed_text&.length || 0)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, transcribed_text.to_s)
  end

  def set_moderation_result_attributes(span, result)
    span.set_attribute('moderation.flagged', result.flagged?) if result.respond_to?(:flagged?)
    span.set_attribute('moderation.categories', result.flagged_categories.to_json) if result.respond_to?(:flagged_categories)
    output = {
      flagged: result.respond_to?(:flagged?) ? result.flagged? : nil,
      categories: result.respond_to?(:flagged_categories) ? result.flagged_categories : []
    }
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, output.to_json)
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
    span.status = OpenTelemetry::Trace::Status.error(error.to_s.truncate(1000))
  end
end
