# Log only: the reply goes out unchanged and the conversation stays with Captain. This counts replies that say a person
# is taking over while the handoff tool did not run, so we can see how often it happens before the handoff field acts.
module Captain::Assistant::HandoffFieldDetection
  include Integrations::LlmInstrumentationConstants

  private

  # Register this before the tracing callbacks, which finish the root span when the run completes.
  def add_handoff_field_detection(runner, handoff_tool_name)
    runner.on_run_complete do |agent_name, result, context_wrapper|
      record_handoff_without_tool(agent_name, result, context_wrapper, handoff_tool_name)
    end
  end

  def record_handoff_without_tool(agent_name, result, context_wrapper, handoff_tool_name)
    return unless handoff_field_set?(result) && !handoff_completed?

    agent_has_handoff_tool = agent_has_tool?(agent_name, handoff_tool_name)
    Rails.logger.info(
      "[CAPTAIN][AgentRunnerService] Handoff field set without the handoff tool for account=#{@assistant.account_id} " \
      "conversation=#{@conversation&.display_id} agent_has_handoff_tool=#{agent_has_handoff_tool}"
    )

    root_span = context_wrapper&.context&.dig(:__otel_tracing, :root_span)
    return unless root_span

    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'handoff_without_tool'), 'true')
    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'agent_has_handoff_tool'), agent_has_handoff_tool.to_s)
  end

  def handoff_field_set?(result)
    result.output.is_a?(Hash) && result.output.with_indifferent_access[:handoff] == true
  end

  def agent_has_tool?(agent_name, tool_name)
    agent = @agents.find { |wired_agent| wired_agent.name == agent_name }
    agent.present? && agent.tools.any? { |tool| tool.name == tool_name }
  end
end
