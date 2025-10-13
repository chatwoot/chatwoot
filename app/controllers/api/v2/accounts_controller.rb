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
    @user, @account = AccountBuilder.new(
      email: account_params[:email],
      user_password: account_params[:password],
      locale: account_params[:locale],
      user: current_user
    ).perform

    fetch_account_and_user_info
    update_account_info if @account.present?

    if @user
      # Prepare data for ALOOSTUDIO webhook
      first_name, last_name = (account_params[:user_full_name] || '').split(' ', 2)
      payload = {
        firstName: first_name,
        lastName: last_name,
        email: account_params[:email],
        password: account_params[:password],
        companyName: account_params[:account_name]
      }
      webhook_url = ENV.fetch('ALOOSTUDIO_WEBHOOK_URL', nil)
      api_token = ENV.fetch('ALOOSTUDIO_API_TOKEN', nil)
      webhook_response = nil
      begin
        conn = Faraday.new do |f|
          f.options.timeout = 60
          f.options.open_timeout = 60
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
        response = conn.post(webhook_url, payload) do |req|
          req.headers['x-api-token'] = api_token
          req.headers['Content-Type'] = 'application/json'
        end
        webhook_response = response.body
        @user.update(clerk_user_id: webhook_response.dig('clerkId')) if webhook_response['success'] && webhook_response.dig('clerkId')
      rescue StandardError => e
        Rails.logger.error("ALOOSTUDIO webhook call failed: #{e.message}")
      end
      send_auth_headers(@user)
      render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  private

  def account_attributes
    {
      custom_attributes: @account.custom_attributes.merge({ 'onboarding_step' => 'profile_update' })
    }
  end

  def update_account_info
    @account.update!(
      account_attributes
    )
  end

  def fetch_account_and_user_info; end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def account_params
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :user_full_name)
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' if GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'true') == 'false'
  end

  def validate_captcha
    raise ActionController::InvalidAuthenticityToken, 'Invalid Captcha' unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?
  end
end

Api::V2::AccountsController.prepend_mod_with('Api::V2::AccountsController')
