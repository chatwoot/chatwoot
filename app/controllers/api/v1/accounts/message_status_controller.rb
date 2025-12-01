class Api::V1::Accounts::MessageStatusController < Api::V1::Accounts::BaseController
  def status
    message_ids = permitted_params[:ids] || []

    if message_ids.empty?
      render json: { error: 'ids parameter is required' }, status: :bad_request
      return
    end

    @messages = Current.account.messages.where(id: message_ids)

    render json: { messages: @messages.map { |msg| { ID: msg.id, Status: msg.status } } }
  end

  private

  def permitted_params
    params.permit(ids: [])
  end
end

