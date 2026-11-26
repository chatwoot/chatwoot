# Log only: count replies that set the handoff field while the handoff tool was not called. The reply goes out unchanged
# and the conversation stays pending, so we can see how often this happens before the field changes anything.
module Captain::Assistant::HandoffFieldDetection
  include Integrations::LlmInstrumentationConstants

  private

  # Register this before the tracing callbacks, which finish the root span when the run completes.
  def add_handoff_field_detection(runner)
    runner.on_run_complete do |_agent_name, result, context_wrapper|
      record_handoff_without_tool(result, context_wrapper)
    end
  end

  def record_handoff_without_tool(result, context_wrapper)
    return unless handoff_without_tool?(result)

    Rails.logger.info(
      "[CAPTAIN][AgentRunnerService] Handoff field set without the handoff tool for account=#{@assistant.account_id} " \
      "conversation=#{@conversation.display_id}"
    )
    root_span = context_wrapper&.context&.dig(:__otel_tracing, :root_span)
    root_span&.set_attribute(format(ATTR_LANGFUSE_METADATA, 'handoff_without_tool'), 'true')
  end

  # Skip the playground, which has no conversation, a handoff tool call even when it failed, because the job then hands off,
  # leaked tool call text, which is retried, and a reply that a newer customer message discards.
  def handoff_without_tool?(result)
    return false unless result.output.is_a?(Hash) && result.output.with_indifferent_access[:handoff] == true
    return false if @conversation.blank? || @handoff_tool_called || leaked_tool_call?(result)

    !newer_customer_message_arrived?
  end
end
