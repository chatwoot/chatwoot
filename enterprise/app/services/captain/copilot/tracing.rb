module Captain::Copilot::Tracing
  include Integrations::LlmInstrumentation

  private

  def with_copilot_trace(span_name, params)
    return yield unless ChatwootApp.otel_enabled?

    with_propagated_langfuse_attributes(params) do
      instrument_with_span(span_name, params) do |_span, completed|
        result = yield
        completed.call(result)
        result
      end
    end
  end
end
