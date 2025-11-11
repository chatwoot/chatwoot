class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    if agent_bot_assignment?
      set_agent_bot
    elsif params.key?(:assignee_id)
      set_agent
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  private

  def set_agent
    @agent = Current.account.users.find_by(id: params[:assignee_id])
    @conversation.assignee = @agent
    @conversation.assignee_agent_bot = nil
    @conversation.save!
    render_agent
  end

  def render_agent
    if @agent.nil?
      render json: nil
    else
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: @agent }
    end
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end

  def set_agent_bot
    @agent_bot = find_agent_bot
    @conversation.assignee_agent_bot = @agent_bot
    @conversation.assignee = nil
    @conversation.save!
    render_agent_bot
  end

  def render_agent_bot
    if @agent_bot.nil?
      render json: nil
    else
      render partial: 'api/v1/models/agent_bot', formats: [:json], locals: { resource: @agent_bot }
    end
  end

  def agent_bot_assignment?
    params[:assignee_type].to_s == 'AgentBot'
  end

  def find_agent_bot
    return if params[:assignee_id].blank?

    Current.account.agent_bots.find_by(id: params[:assignee_id])
  end
end
