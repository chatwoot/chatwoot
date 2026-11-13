class Captain::Copilot::Actions::AssignTeam < Captain::Copilot::Actions::BaseAction
  NAME = 'assign_team'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Assign each conversation to a team, or remove its team. Arguments: team_id, a team ID from get_account_directory, ' \
                'or null to remove the team. A new team also removes an assigned agent who is not on that team.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[team_id],
    properties: { team_id: { type: %w[integer null], minimum: 1 } }
  }.deep_stringify_keys.freeze

  # The same write as the dashboard's team menu.
  def perform(conversation)
    return :skipped if conversation.team_id == team&.id

    conversation.with_lock { conversation.update!(team: team) }
    :applied
  end

  def card(_ids)
    team ? super.merge(values: { team: team.name }) : { summary: 'REMOVE_TEAM' }
  end

  private

  def team
    @team ||= @account.teams.find_by(id: @arguments['team_id']) if @arguments['team_id']
  end

  def validate!
    return if @arguments['team_id'].nil? || team

    teams = @account.teams.order(:name).limit(100).map { |item| "#{item.name} (ID #{item.id})" }
    raise ArgumentError, "No team with ID #{@arguments['team_id']} in this account. Teams: #{teams.join(', ')}"
  end
end
