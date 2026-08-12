class Captain::Routines::Operations::Actions::ConversationAddLabel < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.add_label', effect: 'internal_write',
    description: 'Add an existing account label to one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', label: 'label name' },
    required: %w[conversation_id label]
  )
end
