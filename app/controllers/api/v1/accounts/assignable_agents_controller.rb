class Api::V1::Accounts::AssignableAgentsController < Api::V1::Accounts::BaseController
  def index
    @assignable_agents = Current.account.users.where(id: Current.account.inbox_members.where(inbox_id: permitted_params[:inbox_ids]).select(:user_id))
  end

  private

  def permitted_params
    params.permit(inbox_ids: [])
  end
end
