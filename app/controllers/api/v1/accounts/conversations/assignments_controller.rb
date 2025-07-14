class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team/bot to a conversation
  def create
    if params.key?(:assignee_id)
      set_assignee
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  private

  def set_assignee
    @assignee = case params[:assignee_type]
                when 'AgentBot'
                  Current.account.agent_bots.find_by(id: params[:assignee_id])
                else
                  Current.account.users.find_by(id: params[:assignee_id])
                end

    @conversation.assignee = @assignee
    @conversation.save!
    render_assignee
  end

  def render_assignee
    if @assignee.nil?
      render json: nil
    elsif @assignee.is_a?(AgentBot)
      render json: @assignee.webhook_data
    else
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: @assignee }
    end
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end
end
