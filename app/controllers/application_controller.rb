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
    @_ ||= find_current_account
  end

  def find_current_account
    account = Account.find(params[:account_id])
    if current_user
      account_accessible_for_user?(account)
    elsif @resource&.is_a?(AgentBot)
      account_accessible_for_bot?(account)
    end
    switch_locale account
    account
  end

  def switch_locale(account)
    I18n.locale = (I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : nil) || I18n.default_locale
  end

  def account_accessible_for_user?(account)
    render_unauthorized('You are not authorized to access this account') unless account.account_users.find_by(user_id: current_user.id)
  end

  def account_accessible_for_bot?(account)
    render_unauthorized('You are not authorized to access this account') unless @resource.agent_bot_inboxes.find_by(account_id: account.id)
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
    return if !ENV['BILLING_ENABLED'] || !current_user

    if current_subscription.trial? && current_subscription.expiry < Date.current
      render json: { error: 'Trial Expired' }, status: :trial_expired
    elsif current_subscription.cancelled?
      render json: { error: 'Account Suspended' }, status: :account_suspended
    end
  end
end
