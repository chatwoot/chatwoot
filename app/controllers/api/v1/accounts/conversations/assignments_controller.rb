class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assign agent to a conversation
  def create
    # if params[:assignee_id] is not a valid id, it will set to nil, hence unassigning the conversation
    assignee = Current.account.users.find_by(id: params[:assignee_id])
    @conversation.update_assignee(assignee)
    render json: assignee
  end
end
