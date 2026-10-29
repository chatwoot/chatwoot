class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    if params.key?(:assignee_id) || agent_bot_assignment?
      set_agent
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  private

  def set_agent
    validate_agent_assignment!
    resource = Conversations::AssignmentService.new(
      conversation: @conversation,
      assignee_id: params[:assignee_id],
      assignee_type: params[:assignee_type]
    ).perform

    render_agent(resource)
  rescue CustomExceptions::ConversationAssignmentNotAllowed => e
    render_could_not_create_error(e.message)
  end

  def validate_agent_assignment!
    return if agent_bot_assignment?

    assignee = Current.account.users.find_by(id: params[:assignee_id])
    return if assignee.blank?

    Conversations::AssignmentRulesService.new(account: Current.account, assignee: assignee, conversations: [@conversation]).validate!
  end

  def render_agent(resource)
    case resource
    when User
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: resource }
    when AgentBot
      render partial: 'api/v1/models/agent_bot_slim', formats: [:json], locals: { resource: resource }
    else
      render json: nil
    end
  end

  def set_team
    team_id = params[:team_id].to_i
    @team = team_id.positive? ? Current.account.teams.find(team_id) : nil
    @conversation.with_lock do
      @conversation.update!(team: @team)
    end
    render json: @team
  end

  def agent_bot_assignment?
    params[:assignee_type].to_s == 'AgentBot'
  end
end

Api::V1::Accounts::Conversations::AssignmentsController.prepend_mod_with(
  'Api::V1::Accounts::Conversations::AssignmentsController'
)
