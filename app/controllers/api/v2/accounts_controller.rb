class Api::V2::AccountsController < Api::BaseController
  include AuthHelper

  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :validate_captcha, only: [:create]
  before_action :fetch_account, except: [:create]
  before_action :check_authorization, except: [:create]

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def create
    @user, @account = build_account
    process_account_info
    render_response
  rescue StandardError => e
    Rails.logger.error("Account creation failed: #{e.message}")
    render_error_response(CustomExceptions::Account::SignupFailed.new({}))
  end

  private

  def build_account
    AccountBuilder.new(
      **base_account_params.merge(
        dealership_id_param
      )
    ).perform
  end

  def base_account_params
    {
      email: account_params[:email],
      user_password: account_params[:password],
      locale: account_params[:locale],
      user: current_user
    }
  end

  def dealership_id_param
    account_params[:dealership_id].present? ? { dealership_id: account_params[:dealership_id] } : {}
  end

  def process_account_info
    return unless @account

    fetch_account_and_user_info
    update_account_info
  rescue StandardError => e
    Rails.logger.error("Error processing account info: #{e.message}")
    raise CustomExceptions::Account::UserErrors, e.message
  end

  def render_response
    return render_error_response(CustomExceptions::Account::SignupFailed.new({})) unless @user

    send_auth_headers(@user)
    render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
  end

  def account_attributes
    {
      dealership_id: account_params[:dealership_id],
      custom_attributes: (@account.custom_attributes || {}).merge('onboarding_step' => 'profile_update')
    }
  end

  def update_account_info
    return if @account.blank?

    @account.update!(account_attributes)
  end

  def fetch_account_and_user_info; end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def account_params
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :auto_resolve_duration, :user_full_name, :dealership_id)
  end

  def check_signup_enabled
    signup_setting = GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false')
    raise ActionController::RoutingError, 'Not Found' if signup_setting == 'false'
  end

  def validate_captcha
    raise ActionController::InvalidAuthenticityToken, 'Invalid Captcha' unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?
  end
end

Api::V2::AccountsController.prepend_mod_with('Api::V2::AccountsController')
