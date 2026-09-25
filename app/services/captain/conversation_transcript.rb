class Captain::ConversationTranscript
  MESSAGE_LIMIT = 20
  TOKEN_BUDGET = 15_000
  CHARACTERS_PER_TOKEN = 4

  pattr_initialize [:conversation!]

  def self.entry(message, text = message.content_for_llm)
    { sender: message.incoming? ? 'customer' : 'agent', text: text }
  end

  # Walks newest-first so the latest messages survive the token budget; returns chronological order.
  def messages
    remaining = TOKEN_BUDGET * CHARACTERS_PER_TOKEN
    messages = []

    conversation.messages
                .where(message_type: [:incoming, :outgoing], private: false)
                .reorder(id: :desc)
                .limit(MESSAGE_LIMIT)
                .each do |message|
      content = message.content_for_llm
      next if content.blank? || message.deleted
      break if remaining <= 0

      text = content[0, remaining]
      remaining -= text.length
      messages.prepend(self.class.entry(message, text))
    end

    messages
  end
end
