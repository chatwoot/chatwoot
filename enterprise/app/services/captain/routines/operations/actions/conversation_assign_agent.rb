class Captain::Routines::Operations::Actions::ConversationAssignAgent < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.assign_agent', effect: 'internal_write', approval: 'workspace_policy',
    description: 'Assign one conversation to an account agent.',
    arguments: { conversation_id: 'conversation ID or reference', agent: 'agent name, email, ID, or reference' },
    required: %w[conversation_id agent]
  )
end
