class Captain::Routines::Operations::Actions::ConversationAssignTeam < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.assign_team', effect: 'internal_write',
    description: 'Assign one conversation to an account team.',
    arguments: { conversation_id: 'conversation ID or reference', team: 'team name, ID, or reference' },
    required: %w[conversation_id team]
  )
end
