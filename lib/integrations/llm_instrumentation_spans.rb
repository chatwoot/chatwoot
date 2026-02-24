# frozen_string_literal: true

require 'opentelemetry_config'

module Integrations::LlmInstrumentationSpans
  include Integrations::LlmInstrumentationConstants
  include Integrations::LlmUsageDetailsBuilder

  def tracer
    @tracer ||= OpentelemetryConfig.tracer
  end

  def start_llm_turn_span(params)
    return unless ChatwootApp.otel_enabled?

    span = tracer.start_span(params[:span_name])
    set_llm_turn_request_attributes(span, params)
    set_llm_turn_prompt_attributes(span, params[:messages]) if params[:messages]

    @pending_llm_turn_spans ||= []
    @pending_llm_turn_spans.push(span)
  rescue StandardError => e
    Rails.logger.warn "Failed to start LLM turn span: #{e.message}"
  end

  def end_llm_turn_span(message)
    return unless ChatwootApp.otel_enabled?

    span = @pending_llm_turn_spans&.pop
    return unless span

    set_llm_turn_response_attributes(span, message) if message
    span.finish
  rescue StandardError => e
    Rails.logger.warn "Failed to end LLM turn span: #{e.message}"
  end

  def start_tool_span(tool_call)
    return unless ChatwootApp.otel_enabled?

    tool_name = tool_call.name.to_s
    span = tracer.start_span(format(TOOL_SPAN_NAME, tool_name))
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_TYPE, 'tool')
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, tool_call.arguments.to_json)

    @pending_tool_spans ||= []
    @pending_tool_spans.push(span)
  rescue StandardError => e
    Rails.logger.warn "Failed to start tool span: #{e.message}"
  end

  def end_tool_span(result)
    return unless ChatwootApp.otel_enabled?

    span = @pending_tool_spans&.pop
    return unless span

    output = result.is_a?(String) ? result : result.to_json
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, output)
    span.finish
  rescue StandardError => e
    Rails.logger.warn "Failed to end tool span: #{e.message}"
  end

  private

  def set_llm_turn_request_attributes(span, params)
    provider = determine_provider(params[:model])
    span.set_attribute(ATTR_GEN_AI_PROVIDER, provider)
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model]) if params[:model]
    span.set_attribute(ATTR_GEN_AI_REQUEST_TEMPERATURE, params[:temperature]) if params[:temperature]
  end

  def set_llm_turn_prompt_attributes(span, messages)
    messages.each_with_index do |msg, idx|
      span.set_attribute(format(ATTR_GEN_AI_PROMPT_ROLE, idx), msg[:role])
      span.set_attribute(format(ATTR_GEN_AI_PROMPT_CONTENT, idx), msg[:content])
    end
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, messages.to_json)
  end

  def set_llm_turn_response_attributes(span, message)
    span.set_attribute(ATTR_GEN_AI_COMPLETION_ROLE, message.role.to_s) if message.respond_to?(:role)
    span.set_attribute(ATTR_GEN_AI_COMPLETION_CONTENT, message.content.to_s) if message.respond_to?(:content)
    set_llm_turn_usage_attributes(span, message)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, message.content.to_s) if message.respond_to?(:content)
  end

  def set_llm_turn_usage_attributes(span, message)
    usage_details = llm_turn_usage_details(message)
    return if usage_details.blank?

    span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, usage_details[:input]) if usage_details[:input]
    span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, usage_details[:output]) if usage_details[:output]
    span.set_attribute(ATTR_GEN_AI_USAGE_TOTAL_TOKENS, usage_details[:total]) if usage_details[:total]
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_USAGE_DETAILS, usage_details.to_json)
  end

  def llm_turn_usage_details(message)
    usage_details_from_message(message, provider: llm_turn_provider(message))
  end

  def llm_turn_provider(message)
    model_name = message.respond_to?(:model_id) ? message.model_id : nil
    return 'openai' if model_name.blank?

    model = model_name.to_s.downcase

    LlmConstants::PROVIDER_PREFIXES.each do |provider, prefixes|
      return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
    end

    'openai'
  end
end
