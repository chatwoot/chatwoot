class Onehash::Api::CalEventController < Onehash::IntegrationController
  before_action :validate_update_params, only: [:update]
  before_action :validate_delete_params, only: [:destroy]
  before_action :set_user, only: [:update, :destroy]

  def index
    users = User.all
    render json: users
  end

  def update
    update_cal_events(user_update_params)

    if @user.save
      render json: @user, status: :ok
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    uid = user_delete_params[:uid]

    current_cal_events = @user.custom_attributes['cal_events'] || []

    updated_cal_events = current_cal_events.reject { |event| event['uid'] == uid }

    @user.custom_attributes['cal_events'] = updated_cal_events

    if @user.save
      render json: { message: 'Event successfully deleted' }, status: :ok
    else
      render json: { error: 'Failed to update user' }, status: :unprocessable_entity
    end
  end

  private

  def user_update_params
    params.require(:cal_events).map do |event|
      event.permit(:uid, :title, :description, :url)
    end
  end

  def user_delete_params
    params.permit(:email, :uid)
  end

  def set_user
    @user = User.from_email(params[:email])
    render json: { error: 'User not found' }, status: :not_found unless @user
  end

  def validate_update_params
    return if params[:email].present? && params[:cal_events].is_a?(Array)

    render json: { error: 'Email and cal_events are required' }, status: :bad_request
  end

  def validate_delete_params
    return unless params[:email].blank? || params[:uid].blank?

    render json: { error: 'Email and UID are required' }, status: :bad_request
  end

  def update_cal_events(cal_events_params)
    current_cal_events = @user.custom_attributes['cal_events'] || []

    cal_events_params.each do |event|
      update_or_append_event(current_cal_events, event)
    end

    @user.custom_attributes['cal_events'] = current_cal_events
  end

  def update_or_append_event(current_cal_events, event)
    uid = event['uid']
    existing_event = current_cal_events.find { |e| e['uid'] == uid }

    if existing_event
      existing_event.merge!(event)
    else
      current_cal_events << event
    end
  end
end
