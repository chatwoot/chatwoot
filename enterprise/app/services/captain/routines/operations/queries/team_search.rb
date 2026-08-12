class Captain::Routines::Operations::Queries::TeamSearch < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'teams.search', effect: 'read', approval: 'never',
    description: 'Resolve an account team by name or ID.',
    arguments: { query: 'team name or ID' }, required: %w[query]
  )
end
