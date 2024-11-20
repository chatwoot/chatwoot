class Onehash::Cal::CalEventController < Onehash::IntegrationController
  before_action :validate_update_params, only: [:update]
  before_action :validate_delete_params, only: [:destroy]
  before_action :set_user, only: [:update, :destroy]

  def update
    events = user_update_params
    CalEventUpdateJob.perform_later(@user.id, events)

    render json: { message: 'Event update is being processed' }, status: :accepted
  end

  def destroy
    uid = params[:uid]
    CalEventDestroyJob.perform_later(@user.id, uid)

    render json: { message: 'Event deletion is being processed' }, status: :accepted
  end

  private

  def user_update_params
    params.require(:cal_events).map do |event|
      event.permit(:uid, :title, :url)
    end
  end

  def set_user
    @user = AccountUser.find(params[:account_user_id]).user
    render json: { error: 'User not found' }, status: :not_found unless @user
  end

  def validate_update_params
    return if params[:account_user_id].present? && params[:cal_events].is_a?(Array)

    render json: { error: 'Account User Id and Cal Events are required' }, status: :bad_request
  end

  def validate_delete_params
    return if params[:account_user_id].present? && params[:uid].present?

    render json: { error: 'Account User Id and Cal event Uid are required' }, status: :bad_request
  end
end
