# frozen_string_literal: true

class Captain::Apropos::Instrumentation::TracingCallbacks < Agents::Instrumentation::TracingCallbacks
  include Integrations::LlmInstrumentationConstants

  def initialize(runtime:, role:, **)
    @runtime = runtime
    @role = role
    super(**)
  end

  def on_tool_start(tool_name, arguments, context_wrapper)
    super(tool_name, Captain::Apropos::Instrumentation.tool_input(tool_name, arguments), context_wrapper)
  end

  def on_tool_complete(tool_name, result, context_wrapper)
    mark_tool_error(result, context_wrapper)
    super(tool_name, Captain::Apropos::Instrumentation.summary(result), context_wrapper)
  end

  def on_run_complete(agent_name, result, context_wrapper)
    tracing = send(:tracing_state, context_wrapper)
    status = result.respond_to?(:error) && result.error ? 'failed' : 'completed'
    Captain::Apropos::Instrumentation.set_attributes(
      tracing&.dig(:root_span),
      @runtime.run_summary.merge('langfuse.trace.metadata.status' => status)
    )
    super
  end

  private

  def mark_tool_error(result, context_wrapper)
    error = Captain::Apropos::Instrumentation.error_from(result)
    return if error.blank?

    span = send(:tracing_state, context_wrapper)&.dig(:current_tool_span)
    return unless span

    span.set_attribute(ATTR_GEN_AI_RESPONSE_ERROR, error.to_s.truncate(1_000))
    span.status = OpenTelemetry::Trace::Status.error(error.to_s.truncate(1_000))
  end

  def llm_output_text(response)
    Captain::Apropos::Instrumentation.generation_output(response).to_json
  end

  def set_run_output_attributes(root_span, result)
    return unless result.respond_to?(:output)

    summary = Captain::Apropos::Instrumentation.summary(result.output).to_json
    root_span.set_attribute(ATTR_LANGFUSE_TRACE_OUTPUT, summary)
    root_span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, summary)
  end

  def set_llm_response_attributes(span, response, _output)
    span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, response.input_tokens) if response.respond_to?(:input_tokens) && response.input_tokens
    span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, response.output_tokens) if response.respond_to?(:output_tokens) && response.output_tokens
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, Captain::Apropos::Instrumentation.generation_output(response).to_json)
  end
end
