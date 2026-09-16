# frozen_string_literal: true

class Captain::Apropos::Instrumentation::AttributeProvider
  include Integrations::LlmInstrumentationConstants

  def initialize(runtime, role)
    @runtime = runtime
    @role = role
  end

  def call(context_wrapper)
    trace_input = context_wrapper&.context&.dig(:apropos_trace_input)
    @runtime.langfuse_attributes(role: @role).merge(
      ATTR_LANGFUSE_TRACE_INPUT => trace_input.to_json,
      ATTR_LANGFUSE_OBSERVATION_INPUT => trace_input.to_json
    )
  end

  def generation_attributes(_context_wrapper, _chat, message)
    {
      format(ATTR_LANGFUSE_OBSERVATION_METADATA, 'role') => @role,
      format(ATTR_LANGFUSE_OBSERVATION_METADATA, 'has_tool_calls') => message_has_tool_calls?(message).to_s
    }
  end

  private

  def message_has_tool_calls?(message)
    message.respond_to?(:tool_calls) && message.tool_calls.respond_to?(:any?) && message.tool_calls.any?
  end
end
