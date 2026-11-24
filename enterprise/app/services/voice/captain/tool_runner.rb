# Runs one tool call from Vapi with the same Captain tools chat uses, and returns the text the voice model reads back
class Voice::Captain::ToolRunner
  # Leaves time for the caller to hear "connecting you now" before Twilio moves them to the agents' ringing
  HANDOFF_REDIRECT_DELAY = 3.seconds

  ToolContext = Struct.new(:state)

  pattr_initialize [:session!, :name!, :arguments!]

  def perform
    tool = session.assistant.agent.tools.find { |candidate| candidate.name == name }
    return "Unknown tool: #{name}" if tool.nil?

    result = tool.execute(ToolContext.new(session.tool_state), **arguments.symbolize_keys)
    redirect_to_agents if handed_off?(tool)
    result.to_s
  end

  private

  def handed_off?(tool)
    tool.is_a?(::Captain::Tools::HandoffTool) && session.conversation.reload.open?
  end

  def redirect_to_agents
    Voice::Captain::HandoffRedirectJob.set(wait: HANDOFF_REDIRECT_DELAY).perform_later(session.inbox.id, session.twilio_call_sid)
  end
end
