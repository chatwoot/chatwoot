class Captain::Routines::Operations::Queries::AgentGetWorkload < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'agents.get_workload', effect: 'read',
    description: 'Load current assignment and capacity information for an agent.',
    arguments: { agent: 'agent name, email, ID, or reference' }, required: %w[agent]
  )
end
