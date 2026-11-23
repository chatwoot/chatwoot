# Records a reply suggestion in Langfuse as one trace, in the conversation's session. The service sets @discarded and
# @credit_used while it runs, and the trace ends with both.
module Captain::Copilot::ReplySuggestionTracing
  include Integrations::LlmInstrumentationConstants

  TRACE_NAME = 'llm.captain.copilot'.freeze

  private

  def with_trace(conversation, target_message)
    return yield unless ChatwootApp.otel_enabled?

    OpentelemetryConfig.tracer.in_span(TRACE_NAME, attributes: trace_attributes(conversation, target_message)) do |span|
      response = yield
      span.set_attribute(ATTR_LANGFUSE_TRACE_OUTPUT, response.to_json)
      response
    ensure
      write_final_trace_metadata(span)
    end
  end

  def trace_attributes(conversation, target_message)
    {
      ATTR_LANGFUSE_USER_ID => @account.id.to_s,
      ATTR_LANGFUSE_SESSION_ID => "#{@account.id}_#{conversation.display_id}",
      ATTR_LANGFUSE_TAGS => ['copilot'].to_json,
      format(ATTR_LANGFUSE_METADATA, 'assistant_id') => @assistant.id.to_s,
      format(ATTR_LANGFUSE_METADATA, 'conversation_display_id') => conversation.display_id.to_s,
      format(ATTR_LANGFUSE_METADATA, 'source') => 'copilot_reply_suggestion',
      format(ATTR_LANGFUSE_METADATA, 'feature_name') => 'copilot',
      ATTR_LANGFUSE_TRACE_INPUT => { target_message_id: target_message&.id }.to_json
    }
  end

  def write_final_trace_metadata(span)
    span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'discarded'), @discarded.to_s)
    span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'credit_used'), @credit_used.to_s)
  end
end
