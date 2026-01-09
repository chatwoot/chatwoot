module Captain::ChatGenerationRecorder
  extend ActiveSupport::Concern
  include Integrations::LlmInstrumentationConstants

  private

  def record_llm_generation(chat, message)
    return unless valid_llm_message?(message)

    # Create a generation span with model and token info for Langfuse cost calculation.
    # Note: span duration will be near-zero since we create and end it immediately, but token counts are what Langfuse uses for cost calculation.
    tracer.in_span("llm.captain.#{feature_name}.generation") do |span|
      set_generation_span_attributes(span, chat, message)
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to record LLM generation: #{e.message}"
  end

  # Skip non-LLM messages (e.g., tool results that RubyLLM processes internally).
  # Check for assistant role rather than token presence - some providers/streaming modes
  # may not return token counts, but we still want to capture the generation for evals.
  def valid_llm_message?(message)
    message.respond_to?(:role) && message.role.to_s == 'assistant'
  end

  def set_generation_span_attributes(span, chat, message)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, determine_provider(@model))
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, @model)
    span.set_attribute(ATTR_GEN_AI_REQUEST_TEMPERATURE, temperature)
    span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, message.input_tokens)
    span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, message.output_tokens) if message.respond_to?(:output_tokens) && message.output_tokens

    # Capture input (messages sent to LLM) and output for evals
    input_messages = chat.messages[0...-1].map { |m| { role: m.role.to_s, content: m.content.to_s } }
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, input_messages.to_json)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, message.content.to_s) if message.respond_to?(:content)
  end
end
