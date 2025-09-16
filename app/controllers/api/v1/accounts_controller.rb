class Api::V1::AccountsController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper

  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :ensure_account_name, only: [:create]
  before_action :validate_captcha, only: [:create]
  before_action :fetch_account, except: [:create]
  before_action :check_authorization, except: [:create]

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::InvalidParams,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def show
    @latest_chatwoot_version = ::Redis::Alfred.get(::Redis::Alfred::LATEST_CHATWOOT_VERSION)
    render 'api/v1/accounts/show', format: :json
  end

  def create
    @user, @account = AccountBuilder.new(
      account_name: account_params[:account_name],
      user_full_name: account_params[:user_full_name],
      email: account_params[:email],
      user_password: account_params[:password],
      locale: account_params[:locale],
      user: current_user,
      phoneNumber:account_params[:phoneNumber]
    ).perform

    Rails.logger.info "User: #{@user.inspect}, Account: #{@account.inspect}"

    if @user && @account
      # Assign Free Trial subscription to the newly created account
      assign_free_trial_subscription(@account)

      send_auth_headers(@user)
      render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  def cache_keys
    expires_in 10.seconds, public: false, stale_while_revalidate: 5.minutes
    render json: { cache_keys: cache_keys_for_account }, status: :ok
  end

  def update
    @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email, :auto_resolve_duration))
    @account.custom_attributes.merge!(custom_attributes_params)
    @account.custom_attributes['onboarding_step'] = 'invite_team' if @account.custom_attributes['onboarding_step'] == 'account_update'
    @account.save!
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  private

  def assign_free_trial_subscription(account)
    free_trial_plan = SubscriptionPlan.find_by(name: 'Free Trial')

    Rails.logger.info "Free Trial Plan: #{free_trial_plan.inspect}"
    
    if free_trial_plan.present?
      # Create a new subscription for the account
      subscription = Subscription.create!(
        account_id: account.id,
        plan_name: free_trial_plan.name,
        max_mau: free_trial_plan.max_mau,
        max_ai_agents: free_trial_plan.max_ai_agents,
        max_ai_responses: free_trial_plan.max_ai_responses,
        max_human_agents: free_trial_plan.max_human_agents,
        max_channels: free_trial_plan.max_channels,
        available_channels: free_trial_plan.available_channels,
        support_level: free_trial_plan.support_level,
        subscription_plan_id: free_trial_plan.id,
        status: 'active',
        starts_at: Time.current,
        ends_at: Time.current + free_trial_plan.duration_days.days,
        amount_paid: free_trial_plan.monthly_price,
        price: free_trial_plan.monthly_price,
        payment_status: "paid"
      )

      # Update account.active_subscription_id
      account.update!(active_subscription_id: subscription.id)
    end
  rescue StandardError => e
    Rails.logger.error "Error assigning Free Trial subscription: #{e.message}"
    # Continue with account creation even if subscription assignment fails
  end

  def ensure_account_name
    # ensure that account_name and user_full_name is present
    # this is becuase the account builder and the models validations are not triggered
    # this change is to align the behaviour with the v2 accounts controller
    # since these values are not required directly there
    return if account_params[:account_name].present?
    return if account_params[:user_full_name].present?

    raise CustomExceptions::Account::InvalidParams.new({})
  end

  def cache_keys_for_account
    {
      label: fetch_value_for_key(params[:id], Label.name.underscore),
      inbox: fetch_value_for_key(params[:id], Inbox.name.underscore),
      team: fetch_value_for_key(params[:id], Team.name.underscore)
    }
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def account_params
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :auto_resolve_duration, :user_full_name,:phoneNumber)
  end

  def custom_attributes_params
    params.permit(:industry, :company_size, :timezone)
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' if GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false') == 'false'
  end

  def validate_captcha
    raise ActionController::InvalidAuthenticityToken, 'Invalid Captcha' unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
