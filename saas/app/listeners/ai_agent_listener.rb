# frozen_string_literal: true

# Listens for incoming messages and routes them to an AI agent if the inbox has one configured.
# Runs asynchronously via AsyncDispatcher → Sidekiq EventDispatcherJob.
class AiAgentListener < BaseListener
  def message_created(event)
    message, account = extract_message_and_account(event)

    return unless processable?(message)

    ai_agent = Saas::AiAgentInbox.active_agent_for(message.inbox)
    return unless ai_agent

    AiAgentReplyJob.perform_later(
      message_id: message.id,
      ai_agent_id: ai_agent.id,
      account_id: account.id
    )
  end

  private

  def processable?(message)
    # Only process incoming customer messages (not outgoing, activity, etc.)
    return false unless message.incoming?
    # Skip if conversation is already assigned to a human agent
    return false if message.conversation.assignee_id.present? && !message.conversation.assignee.is_a?(AgentBot)
    # Skip if conversation is resolved
    return false if message.conversation.resolved?

    true
  end
end
