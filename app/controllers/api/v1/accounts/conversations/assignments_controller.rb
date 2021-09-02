class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    set_assignee
  end

  private

  def set_assignee
    # if params[:assignee_id] is not a valid id, it will set to nil, hence unassigning the conversation
    if params.key?(:assignee_id)
      @assignee = Current.account.users.find_by(id: params[:assignee_id])
      @conversation.update_assignee(@assignee)
      if @assignee.nil?
        render json: nil
      elsif
        render partial: 'api/v1/models/agent.json.jbuilder', locals: { resource: @assignee }
      end
    elsif params.key?(:team_id)
      @assignee = Current.account.teams.find_by(id: params[:team_id])
      @conversation.update!(team: @assignee)
      render json: @assignee
    end
  end
end
