class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pundit
  include SwitchLocale

  skip_before_action :verify_authenticity_token

  before_action :set_current_user, unless: :devise_controller?
  around_action :switch_locale
  around_action :handle_with_exception, unless: :devise_controller?

  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  private

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    Raven.capture_exception(e)
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError
    render_unauthorized('You are not authorized to do this action')
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
  end

  def set_current_user
    @user ||= current_user
    Current.user = @user
  end

  def current_subscription
    @subscription ||= Current.account.subscription
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

  def pundit_user
    {
      user: Current.user,
      account: Current.account,
      account_user: Current.account_user
    }
  end
end
