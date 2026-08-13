class Captain::Routines::Operations::Queries::AgentListAvailable < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'agents.list_available', effect: 'read',
    description: 'List agents currently available for an inbox or team.',
    arguments: { inbox: 'inbox name or ID', team: 'team name or ID' }
  )

  def execute(inbox: nil, team: nil)
    scope = account.account_users.online.includes(:user)
    scope = scope.where(user_id: inbox!(inbox).assignable_agents.map(&:id)) if inbox.present?
    scope = scope.where(user_id: team!(team).member_ids) if team.present?
    scope.order(:user_id).map { |account_user| agent_data(account_user.user) }
  end
end
