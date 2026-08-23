class Captain::Conversation::SimpleReplyService
  pattr_initialize [:conversation!, :assistant!]

  # First layer of the assistant pipeline: deterministic keyword replies that
  # run before any LLM work. Returns true when a reply was posted, so the
  # caller can skip LLM generation entirely.
  def perform
    matched_reply = matching_reply
    return false if matched_reply.blank?

    create_bot_reply(matched_reply)
    true
  end

  # Resolves the deterministic simple reply for the given customer content,
  # without posting anything. Used both by the conversation pipeline and by the
  # agent runner (playground), keeping the keyword layer in one place.
  def matching_reply_for(customer_content)
    return if customer_content.blank?

    assistant.simple_replies.enabled.find { |reply| reply.matches?(customer_content) }
  end

  private

  def matching_reply
    matching_reply_for(latest_customer_content)
  end

  def latest_customer_content
    conversation.messages.incoming.last&.content
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
