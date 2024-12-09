class Onehash::Cal::CalEventController < Onehash::IntegrationController
  before_action :validate_update_params, only: [:update]
  before_action :validate_delete_params, only: [:destroy]

  def update
    events = user_update_params

    CalEventUpdateJob.perform_later(params[:account_user_ids], events)

    render json: { message: 'Event update is being processed for multiple users' }, status: :accepted
  end

  def destroy
    uids = Array(params[:uids])

    account_user_ids = params[:account_user_ids].split(',')
    CalEventDestroyJob.perform_later(account_user_ids, uids)

    render json: { message: 'Event deletion is being processed for multiple users' }, status: :accepted
  end

  private

  def user_update_params
    params.require(:cal_events).map do |event|
      event.permit(:uids, :title, :url)
    end
  end

  def validate_update_params
    return if params[:account_user_ids].present? && params[:account_user_ids].is_a?(Array) && params[:cal_events].is_a?(Array)

    render json: { error: 'Account User Ids and Cal Events are required' }, status: :bad_request
  end

  def validate_delete_params
    return if params[:account_user_ids].present? && params[:uids].present?

    render json: { error: 'Account User Ids and Cal event Uid are required' }, status: :bad_request
  end
end
