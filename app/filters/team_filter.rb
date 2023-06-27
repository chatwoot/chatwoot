class TeamFilter
  def initialize(conversations, current_user, team)
    @conversations = conversations
    @current_user = current_user
    @team = team
  end

  def filter
    if @current_user.current_account_user.role == 'administrator'
      @conversations = @team ? @conversations.where(team: @team) : @conversations
      return @conversations
    end

    current_user_team_ids = @current_user.teams.pluck(:id)
    excluded_team_ids = Team.where(account_id: Account.first.id, private: true).pluck(:id) - current_user_team_ids

    if @team
      raise Pundit::NotAuthorizedError if excluded_team_ids.to_set.include?(@team.id)

      @conversations.where(team: @team)
    else
      arel = @conversations.arel_table
      @conversations.where(arel[:team_id].not_in(excluded_team_ids).or(arel[:team_id].eq(nil)))
    end
  end
end
