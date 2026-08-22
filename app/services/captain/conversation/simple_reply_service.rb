class Captain::Conversation::SimpleReplyService
  pattr_initialize [:conversation!, :assistant!]

  # First layer of the assistant pipeline: deterministic keyword replies that
  # run before any LLM work. Returns true when a reply was posted, so the
  # caller can skip LLM generation entirely.
  def perform
    matched_reply = find_matching_reply
    return false if matched_reply.blank?

    create_bot_reply(matched_reply)
    true
  end

  private

  def find_matching_reply
    latest_customer_content = conversation.messages.incoming.last&.content
    return if latest_customer_content.blank?

    assistant.simple_replies.enabled.find { |reply| reply.matches?(latest_customer_content) }
  end

  def create_bot_reply(simple_reply)
    conversation.messages.create!(
      message_type: :outgoing,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      sender: assistant,
      content: simple_reply.reply
    )
  end
end
