class Captain::Routines::Operations::Queries::AgentSearch < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'agents.search', effect: 'read',
    description: 'Resolve an account agent by name, email, or ID.',
    arguments: { query: 'agent name, email, or ID' }, required: %w[query]
  )
end
