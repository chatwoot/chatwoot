# Meta only allows the HUMAN_AGENT message tag on replies written by a human agent
# and sent after the standard 24-hour messaging window has closed. Replies inside the
# window, and automated replies from agent bots or Captain, must be sent without it.
# https://developers.facebook.com/docs/features-reference/human-agent/
module Facebook::HumanAgentTagHelpers
  private

  def human_agent_tag_applicable?
    message.sender.is_a?(User) && outside_standard_messaging_window?
  end

  def outside_standard_messaging_window?
    last_incoming_message = conversation.messages.incoming.last
    return false if last_incoming_message.nil?

    last_incoming_message.created_at < Conversations::MessageWindowService::MESSAGING_WINDOW_24_HOURS.ago
  end
end
