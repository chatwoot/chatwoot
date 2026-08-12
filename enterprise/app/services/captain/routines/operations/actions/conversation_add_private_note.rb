class Captain::Routines::Operations::Actions::ConversationAddPrivateNote < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.add_private_note', effect: 'internal_write',
    description: 'Add an internal note to one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', content: 'note content' },
    required: %w[conversation_id content]
  )
end
