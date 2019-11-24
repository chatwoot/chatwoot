class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pundit

  protect_from_forgery with: :null_session

  before_action :set_current_user, unless: :devise_controller?
  before_action :check_subscription, unless: :devise_controller?
  around_action :handle_with_exception, unless: :devise_controller?

  # after_action :verify_authorized
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  private

  def current_account
    @_ ||= current_user.account
  end

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    Raven.capture_exception(e)
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError
    render_unauthorized('You are not authorized to do this action')
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.user = nil
  end

  def set_current_user
    @user ||= current_user
    Current.user = @user
  end

  def current_subscription
    @subscription ||= current_account.subscription
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_internal_server_error(message)
    render json: { error: message }, status: :internal_server_error
  end

  def render_record_invalid(exception)
    render json: {
      message: exception.record.errors.full_messages.join(', ')
    }, status: :unprocessable_entity
  end

  def render_error_response(exception)
    render json: exception.to_hash, status: exception.http_status
  end

  def check_subscription
    # This block is left over from the initial version of chatwoot
    # We might reuse this later in the hosted version of chatwoot.
    return unless ENV['BILLING_ENABLED']

    if current_subscription.trial? && current_subscription.expiry < Date.current
      render json: { error: 'Trial Expired' }, status: :trial_expired
    elsif current_subscription.cancelled?
      render json: { error: 'Account Suspended' }, status: :account_suspended
    end
  end
end
