class Conversations::AssignmentService
  TEAM_ID_UNSET = Object.new.freeze
  private_constant :TEAM_ID_UNSET

  def initialize(conversation:, assignee_id: nil, assignee_type: nil, team_id: TEAM_ID_UNSET)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
    @team_id = team_id
  end

  def perform
    return assign_team if team_assignment?

    agent_bot_assignment? ? assign_agent_bot : assign_agent
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type, :team_id

  def assign_agent
    bot_handoff = bot_handoff_to_human?(assignee)

    conversation.assignee = assignee
    conversation.assignee_agent_bot = nil
    conversation.mark_bot_handoff if bot_handoff
    conversation.save!
    conversation.dispatch_bot_handoff if bot_handoff

    assignee
  end

  def assign_agent_bot
    return unless agent_bot

    conversation.assignee = nil
    conversation.assignee_agent_bot = agent_bot
    conversation.status = :pending
    conversation.save!
    agent_bot
  end

  def assign_team
    conversation.team = team
    validate_current_assignee_team
    conversation.assignee ||= find_assignee_from_team

    bot_handoff = bot_handoff_to_human?(conversation.assignee)
    conversation.assignee_agent_bot = nil if conversation.assignee.present?
    conversation.mark_bot_handoff if bot_handoff
    conversation.save!
    conversation.dispatch_bot_handoff if bot_handoff

    team
  end

  def assignee
    @assignee ||= conversation.account.users.find_by(id: assignee_id)
  end

  def agent_bot
    @agent_bot ||= AgentBot.accessible_to(conversation.account).find_by(id: assignee_id)
  end

  def agent_bot_assignment?
    assignee_type.to_s == 'AgentBot'
  end

  def team_assignment?
    team_id != TEAM_ID_UNSET
  end

  def team
    @team ||= conversation.account.teams.find_by(id: team_id)
  end

  def validate_current_assignee_team
    conversation.assignee = nil if team&.members&.exclude?(conversation.assignee)
  end

  def find_assignee_from_team
    return if team&.allow_auto_assign.blank?

    team_members_with_capacity = conversation.inbox.member_ids_with_assignment_capacity & team.members.ids
    ::AutoAssignment::AgentAssignmentService.new(conversation: conversation, allowed_agent_ids: team_members_with_capacity).find_assignee
  end

  def bot_handoff_to_human?(assignee)
    assignee.present? && conversation.assignee_agent_bot.present? && conversation.pending?
  end
end
