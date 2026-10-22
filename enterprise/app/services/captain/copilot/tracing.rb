module Captain::Copilot::Tracing
  include Integrations::LlmInstrumentation

  private

  # A Copilot turn runs across several jobs. Each job opens its span inside the trace context saved on the turn,
  # so Langfuse shows the whole turn as one trace and groups the thread's turns into one session.
  # The span records input and the block's result as its output. An error is recorded on the span and raised to the job,
  # which reports it, so it is not reported here as well.
  def with_copilot_trace(span_name, params, turn:, input:)
    return yield unless ChatwootApp.otel_enabled?

    params = params.merge(session_id: "copilot_thread_#{turn.copilot_thread_id}")
    OpenTelemetry::Context.with_current(turn_trace_context(turn)) do
      with_propagated_langfuse_attributes(params) do
        tracer.in_span(span_name) do |span|
          set_metadata_attributes(span, params)
          span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, trace_value(input))
          result = yield span
          span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, trace_value(result))
          result
        end
      end
    end
  end

  def trace_value(value)
    value.is_a?(String) ? value : value.to_json
  end

  def turn_trace_context(turn)
    carrier = turn.trace_carrier
    carrier.present? ? OpenTelemetry.propagation.extract(carrier) : OpenTelemetry::Context.current
  end

  # Called inside the turn's first span so later jobs can join its trace.
  def current_trace_carrier
    {}.tap { |carrier| OpenTelemetry.propagation.inject(carrier) }
  end
end
