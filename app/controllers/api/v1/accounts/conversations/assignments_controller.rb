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
    # #region agent log
    File.open(Rails.root.join('debug-b893f4.log'), 'a') do |f|
      f.puts({
        sessionId: 'b893f4',
        runId: 'post-fix-4',
        hypothesisId: 'H',
        location: 'assignments_controller.rb:set_agent',
        message: 'assignment request params',
        data: {
          conversation_id: @conversation.display_id,
          assignee_id: params[:assignee_id],
          assignee_type: params[:assignee_type]
        },
        timestamp: (Time.now.to_f * 1000).to_i
      }.to_json)
    end
    # #endregion

    resource = Conversations::AssignmentService.new(
      conversation: @conversation,
      assignee_id: params[:assignee_id],
      assignee_type: params[:assignee_type]
    ).perform

    render_agent(resource)
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
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end

  def agent_bot_assignment?
    params[:assignee_type].to_s == 'AgentBot'
  end
end
