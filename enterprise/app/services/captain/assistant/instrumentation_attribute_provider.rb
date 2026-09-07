# frozen_string_literal: true

class Captain::Assistant::InstrumentationAttributeProvider
  include Integrations::LlmInstrumentationConstants

  def initialize(service)
    @service = service
  end

  def call(context_wrapper)
    @service.send(:dynamic_trace_attributes, context_wrapper)
  end

  def generation_attributes(_context_wrapper, _chat, message)
    attributes = {
      format(ATTR_LANGFUSE_OBSERVATION_METADATA, 'generation_stage') => generation_stage(message)
    }
    if @service.send(:message_burst_protection_active?)
      attributes[format(ATTR_LANGFUSE_OBSERVATION_METADATA, 'discarded')] = @service.send(:newer_customer_message_arrived?).to_s
    end
    attributes
  end

  private

  def generation_stage(message)
    message_has_tool_calls?(message) ? 'tool_call' : 'final_response'
  end

  def message_has_tool_calls?(message)
    return false unless message.respond_to?(:tool_calls)

    tool_calls = message.tool_calls
    tool_calls.respond_to?(:any?) && tool_calls.any?
  end
end
