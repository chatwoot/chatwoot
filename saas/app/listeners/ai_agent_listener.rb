# frozen_string_literal: true

# Listens for incoming messages and routes them to an AI agent if the inbox has one configured.
# Runs asynchronously via AsyncDispatcher → Sidekiq EventDispatcherJob.
class AiAgentListener < BaseListener
  def message_created(event)
    message, account = extract_message_and_account(event)

    return unless processable?(message)

    agent_inbox = Saas::AiAgentInbox.active_for(message.inbox)
    return unless agent_inbox

    # Deduplicate: skip if another AiAgentReplyJob is already enqueued for this conversation
    # within the last few seconds (prevents double-replies when multiple messages arrive rapidly)
    dedup_key = "ai_agent_reply:#{message.conversation_id}"
    return unless Redis::Alfred.set(dedup_key, '1', nx: true, ex: 5)

    AiAgentReplyJob.perform_later(
      message_id: message.id,
      ai_agent_id: agent_inbox.ai_agent_id,
      account_id: account.id
    )
  end

  private

  def processable?(message)
    # Only process incoming customer messages (not outgoing, activity, etc.)
    return false unless message.incoming?
    # Skip if conversation is resolved
    return false if message.conversation.resolved?
    # Skip messages without any textual content (pure media without caption)
    return false if message.content.blank? && message.attachments.none?

    true
  end
end
