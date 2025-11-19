module Integrations::LlmInstrumentation
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
        # Log instrumentation setup errors but continue with the API call
        Rails.logger.error("LLM instrumentation setup error: #{e.message}")
      end

      result = yield

      begin
        set_completion_attributes(span, result) if result.is_a?(Hash)
      rescue StandardError => e
        # Log instrumentation completion errors but don't affect the result
        Rails.logger.error("LLM instrumentation completion error: #{e.message}")
      end

      result
    end
  end

  private

  def otel_enabled?
    ENV['OTEL_ENABLED'] == 'true'
  end

  def set_request_attributes(span, params)
    span.set_attribute('gen_ai.system', 'openai')
    span.set_attribute('gen_ai.request.model', params[:model])
    span.set_attribute('gen_ai.request.temperature', params[:temperature]) if params[:temperature]
  end

  def set_prompt_messages(span, messages)
    messages.each_with_index do |msg, idx|
      span.set_attribute("gen_ai.prompt.#{idx}.role", msg['role'])
      span.set_attribute("gen_ai.prompt.#{idx}.content", msg['content'])
    end
  end

  def set_metadata_attributes(span, params)
    span.set_attribute('langfuse.user.id', params[:account_id].to_s) if params[:account_id]
    span.set_attribute('langfuse.session.id', params[:conversation_id].to_s) if params[:conversation_id]
    span.set_attribute('langfuse.tags', [params[:feature_name]].to_json)
  end

  def set_completion_attributes(span, result)
    set_completion_message(span, result)
    set_usage_metrics(span, result)
    set_error_attributes(span, result)
  end

  def set_completion_message(span, result)
    return if result[:message].blank?

    span.set_attribute('gen_ai.completion.0.role', 'assistant')
    span.set_attribute('gen_ai.completion.0.content', result[:message])
  end

  def set_usage_metrics(span, result)
    return if result[:usage].blank?

    usage = result[:usage]
    span.set_attribute('gen_ai.usage.prompt_tokens', usage['prompt_tokens']) if usage['prompt_tokens']
    span.set_attribute('gen_ai.usage.completion_tokens', usage['completion_tokens']) if usage['completion_tokens']
    span.set_attribute('gen_ai.usage.total_tokens', usage['total_tokens']) if usage['total_tokens']
  end

  def set_error_attributes(span, result)
    return if result[:error].blank?

    span.set_attribute('gen_ai.response.error', result[:error].to_json)
    span.set_attribute('gen_ai.response.error_code', result[:error_code]) if result[:error_code]
    span.status = OpenTelemetry::Trace::Status.error("API Error: #{result[:error_code]}")
  end
end
