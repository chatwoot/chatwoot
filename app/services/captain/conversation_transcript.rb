class Captain::ConversationTranscript
  MESSAGE_LIMIT = 20
  TOKEN_BUDGET = 15_000
  CHARACTERS_PER_TOKEN = 4
  MESSAGE_TYPES = %w[incoming outgoing].freeze

  pattr_initialize [:conversation!]

  # The single rule for what Captain may read: public customer and agent messages that still have content,
  # cut to the characters the caller has room for.
  def self.entry(message, limit)
    return unless MESSAGE_TYPES.include?(message.message_type) && !message.private? && !message.deleted && !message.forwarded?

    text = message.content_for_llm
    { sender: message.incoming? ? 'customer' : 'agent', text: text[0, limit] } if text.present?
  end

  # Walks newest-first so the latest messages survive the token budget; returns chronological order.
  def messages
    remaining = TOKEN_BUDGET * CHARACTERS_PER_TOKEN
    entries = []

    conversation.messages
                .where(message_type: MESSAGE_TYPES, private: false)
                .not_forwarded
                .reorder(id: :desc)
                .limit(MESSAGE_LIMIT)
                .each do |message|
      break if remaining <= 0

      entry = self.class.entry(message, remaining)
      next unless entry

      remaining -= entry[:text].length
      entries.prepend(entry)
    end

    entries
  end
end
