class Api::V1::Accounts::BulkActionsController < Api::V1::Accounts::BaseController
  before_action :type_matches?

  def create
    if type_matches?
      ::BulkActionsJob.perform_later(
        account: @current_account,
        user: current_user,
        params: permitted_params
      )
      head :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def type_matches?
    ['Conversation'].include?(params[:type])
  end

  def permitted_params
    params.permit(:type, ids: [], fields: [:status, :assignee_id, :team_id], labels: [add: [], remove: []])
  end
end
