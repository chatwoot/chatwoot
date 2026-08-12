class Captain::Routines::Operations::Queries::AgentListAvailable < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'agents.list_available', effect: 'read',
    description: 'List agents currently available for an inbox or team.',
    arguments: { inbox: 'inbox name or ID', team: 'team name or ID' }
  )
end
