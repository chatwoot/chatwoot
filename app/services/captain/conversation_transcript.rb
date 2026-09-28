class Captain::ConversationTranscript
  MESSAGE_LIMIT = 20
  TOKEN_BUDGET = 15_000
  CHARACTERS_PER_TOKEN = 4
  MESSAGE_TYPES = %w[incoming outgoing].freeze

  pattr_initialize [:conversation!]

  # The single rule for what Captain may read: public customer and agent messages that still have content.
  def self.entry(message)
    return unless MESSAGE_TYPES.include?(message.message_type) && !message.private? && !message.deleted

    text = message.content_for_llm
    { sender: message.incoming? ? 'customer' : 'agent', text: text } if text.present?
  end

  # Walks newest-first so the latest messages survive the token budget; returns chronological order.
  def messages
    remaining = TOKEN_BUDGET * CHARACTERS_PER_TOKEN
    entries = []

    conversation.messages
                .where(message_type: MESSAGE_TYPES, private: false)
                .reorder(id: :desc)
                .limit(MESSAGE_LIMIT)
                .each do |message|
      entry = self.class.entry(message)
      next unless entry
      break if remaining <= 0

      entry[:text] = entry[:text][0, remaining]
      remaining -= entry[:text].length
      entries.prepend(entry)
    end

    entries
  end
end
