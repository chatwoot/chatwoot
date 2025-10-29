class Api::V1::Accounts::Contacts::BulkActionsController < Api::V1::Accounts::BaseController
  def create
    Contacts::BulkActionJob.perform_later(
      @current_account.id,
      current_user.id,
      permitted_params
    )

    render json: { success: true, message: 'Bulk label assignment enqueued' }
  end

  private

  def permitted_params
    permitted = params.permit(contact_ids: [], labels: [])
    action_value = request.request_parameters['action']
    permitted[:action] = action_value
    permitted.to_h
  end
end
