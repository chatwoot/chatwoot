class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    if params.key?(:assignee_id)
      set_agent
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  private

  def set_agent
    if params[:assignee_id] == -1
      inbox = Inbox.find(@conversation.inbox_id)
      ::AutoAssignment::AgentAssignmentService.new(
        conversation: @conversation,
        allowed_agent_ids: inbox.member_ids_with_assignment_capacity,
        send_customer_message: true
      ).perform
    else
      @agent = Current.account.users.find_by(id: params[:assignee_id])
      @conversation.assignee = @agent
      @conversation.save!
      render_agent
    end
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
end
