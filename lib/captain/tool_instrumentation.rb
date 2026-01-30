module Captain::ToolInstrumentation
  extend ActiveSupport::Concern

  private

  # Custom instrumentation for tool flows - outputs just the message (not full hash)
  def instrument_tool_session(params)
    return yield unless ChatwootApp.otel_enabled?

    response = nil
    executed = false
    tracer.in_span(params[:span_name]) do |span|
      span.set_attribute('langfuse.user.id', params[:account_id].to_s) if params[:account_id]
      span.set_attribute('langfuse.tags', [params[:feature_name]].to_json)
      span.set_attribute('langfuse.observation.input', params[:messages].to_json)

      response = yield
      executed = true

      # Output just the message for cleaner Langfuse display
      span.set_attribute('langfuse.observation.output', response[:message] || response.to_json)
    end
    response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    executed ? response : yield
  end

  def record_generation(chat, message, model)
    return unless ChatwootApp.otel_enabled?
    return unless message.respond_to?(:role) && message.role.to_s == 'assistant'

    tracer.in_span("llm.#{event_name}.generation") do |span|
      span.set_attribute('gen_ai.system', 'openai')
      span.set_attribute('gen_ai.request.model', model)
      span.set_attribute('gen_ai.usage.input_tokens', message.input_tokens)
      span.set_attribute('gen_ai.usage.output_tokens', message.output_tokens) if message.respond_to?(:output_tokens)
      span.set_attribute('langfuse.observation.input', format_chat_messages(chat))
      span.set_attribute('langfuse.observation.output', message.content.to_s) if message.respond_to?(:content)
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to record generation: #{e.message}"
  end

  def format_chat_messages(chat)
    chat.messages[0...-1].map { |m| { role: m.role.to_s, content: m.content.to_s } }.to_json
  end
end
