# frozen_string_literal: true

require 'opentelemetry_config'

module Integrations::LlmInstrumentation
  include Integrations::LlmInstrumentationConstants
  include Integrations::LlmInstrumentationHelpers
  include Integrations::LlmInstrumentationSpans

  PROVIDER_PREFIXES = {
    'openai' => %w[gpt- o1 o3 o4 text-embedding- whisper- tts-],
    'anthropic' => %w[claude-],
    'google' => %w[gemini-],
    'mistral' => %w[mistral- codestral-],
    'deepseek' => %w[deepseek-]
  }.freeze

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
      set_request_attributes(span, params)
      set_metadata_attributes(span, params)

      # By default, the input and output of a trace are set from the root observation
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, params[:messages].to_json)
      result = yield
      executed = true
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
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
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, arguments.to_json)
      result = yield
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
      result
    end
  end

  def determine_provider(model_name)
    return 'openai' if model_name.blank?

    model = model_name.to_s.downcase

    PROVIDER_PREFIXES.each do |provider, prefixes|
      return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
    end

    'openai'
  end

  private

  def resolve_account(params)
    return params[:account] if params[:account].is_a?(Account)
    return Account.find_by(id: params[:account_id]) if params[:account_id].present?

    nil
  end

  def setup_span_attributes(span, params)
    set_request_attributes(span, params)
    set_prompt_messages(span, params[:messages])
    set_metadata_attributes(span, params)
  end

  def record_completion(span, result)
    if result.respond_to?(:content)
      span.set_attribute(ATTR_GEN_AI_COMPLETION_ROLE, result.role.to_s) if result.respond_to?(:role)
      span.set_attribute(ATTR_GEN_AI_COMPLETION_CONTENT, result.content.to_s)
    elsif result.is_a?(Hash)
      set_completion_attributes(span, result) if result.is_a?(Hash)
    end
  end

  def set_request_attributes(span, params)
    provider = determine_provider(params[:model])
    span.set_attribute(ATTR_GEN_AI_PROVIDER, provider)
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
end
