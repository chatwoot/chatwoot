class Captain::Routines::Operations::Actions::ConversationRemoveLabel < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.remove_label', effect: 'internal_write',
    description: 'Remove a label from one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', label: 'label name' },
    required: %w[conversation_id label]
  )
end
