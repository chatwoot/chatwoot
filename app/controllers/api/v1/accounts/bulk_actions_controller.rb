class Api::V1::Accounts::BulkActionsController < Api::V1::Accounts::BaseController
  def create
    case normalized_type
    when 'Conversation'
      enqueue_conversation_job
      head :ok
    when 'Contact'
      enqueue_contact_job
      head :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def normalized_type
    params[:type].to_s.camelize
  end

  def enqueue_conversation_job
    ::BulkActionsJob.perform_later(
      account: @current_account,
      user: current_user,
      params: conversation_params
    )
  end

  def enqueue_contact_job
    Contacts::BulkActionJob.perform_later(
      @current_account.id,
      current_user.id,
      contact_params
    )
  end

  def conversation_params
    params.permit(:type, :snoozed_until, ids: [], fields: [:status, :assignee_id, :team_id], labels: [add: [], remove: []])
  end

  def contact_params
    params.require(:ids)
    permitted = params.permit(:type, ids: [], labels: [add: []])
    permitted[:ids] = permitted[:ids].map(&:to_i) if permitted[:ids].present?
    permitted
  end
end
