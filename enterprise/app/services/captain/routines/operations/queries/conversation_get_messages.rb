class Captain::Routines::Operations::Queries::ConversationGetMessages < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'conversations.get_messages', effect: 'read',
    description: 'Load recent messages from one conversation for semantic analysis.',
    arguments: {
      conversation_id: 'conversation ID or reference', limit: 'maximum number of messages',
      include_private: 'whether internal notes should be included'
    },
    required: %w[conversation_id]
  )
end
