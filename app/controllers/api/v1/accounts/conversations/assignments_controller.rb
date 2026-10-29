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
    resource = Conversations::AssignmentRulesService.new(account: Current.account, assignee: human_assignee).enforce! do
      Conversations::AssignmentService.new(
        conversation: @conversation,
        assignee_id: params[:assignee_id],
        assignee_type: params[:assignee_type]
      ).perform
    end

    render_agent(resource)
  rescue CustomExceptions::ConversationAssignmentNotAllowed => e
    render_could_not_create_error(e.message)
  end

  def human_assignee
    return unless params[:assignee_type].blank? || params[:assignee_type] == 'User'

    Current.account.users.find_by(id: params[:assignee_id])
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
