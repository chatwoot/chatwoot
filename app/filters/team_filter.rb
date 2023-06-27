class TeamFilter
  def initialize(conversations, current_user, team)
    @conversations = conversations
    @current_user = current_user
    @team = team
  end

  def filter
    return administrator_filter if administrator?
    return team_filter if @team

    arel = @conversations.arel_table
    @conversations.where(arel[:team_id].not_in(excluded_team_ids).or(arel[:team_id].eq(nil)))
  end

  private

  def administrator?
    @current_user.current_account_user.role == 'administrator'
  end

  def administrator_filter
    @team ? @conversations.where(team: @team) : @conversations
  end

  def team_filter
    raise Pundit::NotAuthorizedError if excluded_team_ids.to_set.include?(@team.id)

    @conversations.where(team: @team)
  end

  def excluded_team_ids
    current_user_team_ids = @current_user.teams.pluck(:id)
    Team.where(account_id: Account.first.id, private: true).pluck(:id) - current_user_team_ids
  end
end
