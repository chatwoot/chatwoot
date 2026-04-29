# frozen_string_literal: true

require 'opentelemetry_config'

module Integrations::LlmInstrumentation
  include Integrations::LlmInstrumentationConstants
  include Integrations::LlmInstrumentationHelpers
  include Integrations::LlmInstrumentationSpans

  def instrument_llm_call(params)
    return yield unless ChatwootApp.otel_enabled?

    result = nil
    executed = false
    tracer.in_span(params[:span_name]) do |span|
      setup_span_attributes(span, params)
      result = yield
      executed = true
      record_completion(span, result)
      result
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: resolve_account(params)).capture_exception
    executed ? result : yield
  end

  def instrument_agent_session(params)
    return yield unless ChatwootApp.otel_enabled?

    result = nil
    executed = false
    tracer.in_span(params[:span_name]) do |span|
      set_metadata_attributes(span, params)

      # By default, the input and output of a trace are set from the root observation
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:messages].to_json)
      result = yield
      executed = true
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
      set_error_attributes(span, result) if result.is_a?(Hash)
      result
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: resolve_account(params)).capture_exception
    executed ? result : yield
  end

  def instrument_tool_call(tool_name, arguments)
    # There is no error handling because tools can fail and LLMs should be
    # aware of those failures and factor them into their response.
    return yield unless ChatwootApp.otel_enabled?

    tracer.in_span(format(TOOL_SPAN_NAME, tool_name)) do |span|
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_TYPE, 'tool')
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, arguments.to_json)
      result = yield
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
      set_error_attributes(span, result) if result.is_a?(Hash)
      result
    end
  end

  def instrument_embedding_call(params)
    return yield unless ChatwootApp.otel_enabled?

    instrument_with_span(params[:span_name] || 'llm.embedding', params) do |span, track_result|
      set_embedding_span_attributes(span, params)
      result = yield
      track_result.call(result)
      set_embedding_result_attributes(span, result)
      result
    end
  end

  def instrument_audio_transcription(params)
    return yield unless ChatwootApp.otel_enabled?

    instrument_with_span(params[:span_name] || 'llm.audio.transcription', params) do |span, track_result|
      set_audio_transcription_span_attributes(span, params)
      result = yield
      track_result.call(result)
      set_transcription_result_attributes(span, result)
      result
    end
  end

  def instrument_moderation_call(params)
    return yield unless ChatwootApp.otel_enabled?

    instrument_with_span(params[:span_name] || 'llm.moderation', params) do |span, track_result|
      set_moderation_span_attributes(span, params)
      result = yield
      track_result.call(result)
      set_moderation_result_attributes(span, result)
      result
    end
  end

  def instrument_with_span(span_name, params, &)
    result = nil
    executed = false
    tracer.in_span(span_name) do |span|
      track_result = lambda do |r|
        executed = true
        result = r
      end
      yield(span, track_result)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: resolve_account(params)).capture_exception
    raise unless executed

    result
  end

  private

  def resolve_account(params)
    return params[:account] if params[:account].is_a?(Account)
    return Account.find_by(id: params[:account_id]) if params[:account_id].present?

    nil
  end
end
