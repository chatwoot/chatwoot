class Api::V1::Accounts::BulkActions::StatusChangesController < Api::V1::Accounts::BaseController
  def create
    ::Conversations::StatusChangeJob.perform_later(
      account: @current_account,
      conversation_ids: params[:conversation_ids],
      status: params[:status]
    )
    head :ok
  end

  private

  def status_change_params
    params.permit(:status, conversation_ids: [])
  end
end
