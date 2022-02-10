class Api::V1::Accounts::BulkActionsController < Api::V1::Accounts::BaseController
  def create
    ::BulkActionsJob.perform_later(
      account: @current_account,
      params: permitted_params,
      method_type: :update,
      user: current_user
    )
    head :ok
  end

  def destroy
    ::BulkActionsJob.perform_later(
      account: @current_account,
      params: permitted_params,
      method_type: :delete,
      user: current_user,
    )
    head :ok
  end

  private

  def permitted_params
    params.permit(:status, :assignee_id, :team_id, conversation_ids: [], labels: [])
  end
end
