module Integrations::LlmInstrumentation
  def tracer
    @tracer ||= OpenTelemetry.tracer_provider.tracer('chatwoot')
  end

  def instrument_llm_call(span_name:, account_id:, conversation_id:, feature_name:, model:, messages:, temperature: nil)
    return yield unless otel_enabled?

    tracer.in_span(span_name) do |span|
      # Set GenAI semantic convention attributes
      span.set_attribute('gen_ai.system', 'openai')
      span.set_attribute('gen_ai.request.model', model)
      span.set_attribute('gen_ai.request.temperature', temperature) if temperature

      # Set input using indexed attributes (Langfuse standard format)
      messages.each_with_index do |msg, idx|
        span.set_attribute("gen_ai.prompt.#{idx}.role", msg['role'])
        span.set_attribute("gen_ai.prompt.#{idx}.content", msg['content'])
      end

      # Set Langfuse metadata attributes
      span.set_attribute('langfuse.user.id', account_id.to_s) if account_id
      span.set_attribute('langfuse.session.id', conversation_id.to_s) if conversation_id
      span.set_attribute('langfuse.tags', [feature_name].to_json)

      # Execute the API call
      result = yield

      # Set completion and usage attributes from response
      set_completion_attributes(span, result) if result.is_a?(Hash)

      result
    end
  rescue StandardError => e
    Rails.logger.error("LLM instrumentation error: #{e.message}")
    yield
  end

  private

  def otel_enabled?
    ENV['OTEL_ENABLED'] == 'true'
  end

  def set_completion_attributes(span, result)
    # Set output using indexed attributes (Langfuse standard format)
    if result[:message].present?
      span.set_attribute('gen_ai.completion.0.role', 'assistant')
      span.set_attribute('gen_ai.completion.0.content', result[:message])
    end

    # Set usage metrics
    if result[:usage].present?
      usage = result[:usage]
      span.set_attribute('gen_ai.usage.prompt_tokens', usage['prompt_tokens']) if usage['prompt_tokens']
      span.set_attribute('gen_ai.usage.completion_tokens', usage['completion_tokens']) if usage['completion_tokens']
      span.set_attribute('gen_ai.usage.total_tokens', usage['total_tokens']) if usage['total_tokens']
    end

    # Set error attributes if present
    return unless result[:error].present?

    span.set_attribute('gen_ai.response.error', result[:error].to_json)
    span.set_attribute('gen_ai.response.error_code', result[:error_code]) if result[:error_code]
    span.status = OpenTelemetry::Trace::Status.error("API Error: #{result[:error_code]}")
  end
end
