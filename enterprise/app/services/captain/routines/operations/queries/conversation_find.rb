class Captain::Routines::Operations::Queries::ConversationFind < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'conversations.find', effect: 'read', approval: 'never',
    description: 'Load one conversation with its contact, inbox, assignment, labels, and attributes.',
    arguments: { conversation_id: 'conversation ID or reference' }, required: %w[conversation_id]
  )
end
