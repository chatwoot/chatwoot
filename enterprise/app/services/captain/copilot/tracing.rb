module Captain::Copilot::Tracing
  include Integrations::LlmInstrumentation

  private

  # A Copilot turn runs across several jobs. Each job opens its span inside the trace context saved on the turn,
  # so Langfuse shows the whole turn as one trace and groups the thread's turns into one session.
  # The span records input and the block's result as its output.
  def with_copilot_trace(span_name, params, turn:, input:)
    return yield unless ChatwootApp.otel_enabled?

    params = params.merge(session_id: "copilot_thread_#{turn.copilot_thread_id}")
    OpenTelemetry::Context.with_current(turn_trace_context(turn)) do
      with_propagated_langfuse_attributes(params) do
        instrument_with_span(span_name, params) do |span, completed|
          span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, trace_value(input))
          result = yield span
          span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, trace_value(result))
          completed.call(result)
          result
        end
      end
    end
  end

  def trace_value(value)
    value.is_a?(String) ? value : value.to_json
  end

  def turn_trace_context(turn)
    carrier = turn.context['trace_carrier']
    carrier.present? ? OpenTelemetry.propagation.extract(carrier) : OpenTelemetry::Context.current
  end

  # Called inside the turn's first span so later jobs can join its trace.
  def current_trace_carrier
    {}.tap { |carrier| OpenTelemetry.propagation.inject(carrier) }
  end
end
