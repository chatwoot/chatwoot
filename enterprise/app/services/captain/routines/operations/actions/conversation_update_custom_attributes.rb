class Captain::Routines::Operations::Actions::ConversationUpdateCustomAttributes < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.update_custom_attributes', effect: 'internal_write', approval: 'workspace_policy',
    description: 'Update configured custom attributes on one conversation.',
    arguments: {
      conversation_id: 'conversation ID or reference', attributes: 'object containing custom attribute names and values'
    },
    required: %w[conversation_id attributes]
  )
end
