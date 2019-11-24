class Api::V1::Conversations::AssignmentsController < Api::BaseController
  before_action :set_conversation, only: [:create]

  def create # assign agent to a conversation
    # if params[:assignee_id] is not a valid id, it will set to nil, hence unassigning the conversation
    assignee = current_account.users.find_by(id: params[:assignee_id])
    @conversation.update_assignee(assignee)
    render json: assignee
  end
end
