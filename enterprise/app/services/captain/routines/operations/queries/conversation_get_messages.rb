class Captain::Routines::Operations::Queries::ConversationGetMessages < Captain::Routines::Operations::Query
  returns :collection, of: :message

  configure(
    name: 'conversations.get_messages', effect: 'read',
    description: 'Load recent messages from one conversation for semantic analysis.',
    arguments: {
      conversation_id: 'conversation ID or reference', limit: 'maximum number of messages',
      include_private: 'whether internal notes should be included'
    },
    required: %w[conversation_id]
  )

  def execute(conversation_id:, limit: 20, include_private: false)
    messages = conversation!(conversation_id).messages.where(message_type: %i[incoming outgoing])
    messages = messages.where(private: false) unless ActiveModel::Type::Boolean.new.cast(include_private)
    messages.reorder(created_at: :desc, id: :desc).limit(limit.to_i.clamp(1, 100)).reverse.map { |message| message_data(message) }
  end
end
