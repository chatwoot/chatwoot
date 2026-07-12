class Conversations::TeamAssignmentService
  pattr_initialize [:conversation!, :team_id]

  def perform
    team = find_team
    conversation.update!(team: team)
    maybe_auto_assign_agent(team)
    team
  end

  private

  def find_team
    return if team_id.blank? || %w[0 nil].include?(team_id.to_s)

    conversation.account.teams.find_by(id: team_id)
  end

  def maybe_auto_assign_agent(team)
    return if team.blank?
    return unless team.allow_auto_assign
    return if assignee_on_team?(team)

    allowed_agent_ids = conversation.inbox.member_ids_with_assignment_capacity & team.members.ids
    return if allowed_agent_ids.blank?

    AutoAssignment::AgentAssignmentService.new(
      conversation: conversation,
      allowed_agent_ids: allowed_agent_ids
    ).perform
  end

  def assignee_on_team?(team)
    assignee = conversation.assignee
    return false if assignee.blank?

    team.members.exists?(id: assignee.id)
  end
end
