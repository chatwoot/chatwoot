class Captain::Routines::Operations::Actions::ConversationSetStatus < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.set_status', effect: 'internal_write',
    description: 'Change one conversation to open, pending, or resolved.',
    arguments: { conversation_id: 'conversation ID or reference', status: 'open, pending, or resolved' },
    required: %w[conversation_id status]
  )
end
