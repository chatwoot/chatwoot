class Captain::Routines::Operations::Queries::TeamSearch < Captain::Routines::Operations::Query
  returns :one, of: :team

  configure(
    name: 'teams.search', effect: 'read',
    description: 'Resolve an account team by name or ID.',
    arguments: { query: 'team name or ID' }, required: %w[query]
  )

  def execute(query:)
    team_data(team!(query))
  end
end
