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
  # To removee
  # skip_before_action :verify_subscription,
  #                    only: [:billing_subscription, :show, :stripe_checkout], raise: false

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
      user: current_user
    ).perform
    if @user
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

  def get_ltd
    code = CouponCode.find_by(code: params[:coupon_code])
    if code && (code.partner == 'AppSumo' || code.partner == 'DealMirror')
      if Time.current > code.expiry_date
        render json: { message: 'Coupon code has expired' }, status: :unprocessable_entity
      elsif code.status == 'redeemed'
        render json: { message: 'Coupon code already used' }, status: :unprocessable_entity
      elsif @account.coupon_code_used >= 5
        render json: { message: 'Account limit reached. Cannot add more coupon codes' }, status: :unprocessable_entity
      else
        activate_ltd(code)
        code.update!(account_id: @account.id, account_name: @account.name, status: 'redeemed', redeemed_at: Time.current)
        if @account.coupon_code_used == 4
          render json: { message: 'To upgrade to unlimited agents, please apply the fifth code.' }, status: :ok
        else
          render json: { message: 'Redemption successful' }, status: :ok
        end
      end
    elsif code && (code.partner == 'PitchGround' || code.partner == 'RocketHub' || code.partner == 'DealFuel' || code.partner == 'OneHash')
      if Time.current > code.expiry_date
        render json: { message: 'Coupon code has expired' }, status: :unprocessable_entity
      elsif code.status == 'redeemed'
        render json: { message: 'Coupon code already used' }, status: :unprocessable_entity
      elsif @account.coupon_code_used >= 1
        render json: { message: 'Account limit reached. Cannot add more coupon codes' }, status: :unprocessable_entity
      else
        activate_ltd(code)
        code.update!(account_id: @account.id, account_name: @account.name, status: 'redeemed', redeemed_at: Time.current)
        render json: { message: 'Redemption successful' }, status: :ok
      end
    else
      render json: { message: 'The provided coupon code is invalid or does not exist' }, status: :unprocessable_entity
    end
  end

  def get_ltd_details
    render 'api/v1/accounts/ltd/show', format: :json, locals: { resource: @account }
  end

  def stripe_subscription
    Account::CreateStripeCustomerJob.perform_later(@account) if stripe_customer_id.blank?
    head :no_content
  end

  def stripe_checkout
    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  end

  private

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
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :auto_resolve_duration, :user_full_name)
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

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def create_stripe_billing_session(stripe_customer_id)
    session = Enterprise::Billing::CreateStripeSessionService.new.create_stripe_session(stripe_customer_id)
    render_redirect_url(session.url)
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def activate_ltd(coupon_code)
    code_prefix = coupon_code.code[0, 2]
    partner_name = ''
    if code_prefix == 'AS'
      partner_name = 'AppSumo'
    elsif code_prefix == 'DM'
      partner_name = 'DealMirror'
    elsif code_prefix == 'PG'
      partner_name = 'PitchGround'
    elsif code_prefix == 'RH'
      partner_name = 'RocketHub'
    elsif code_prefix == 'DF'
      partner_name = 'DealFuel'
    elsif code_prefix == 'OH'
      partner_name = 'OneHash'
    end

    if %w[AppSumo DealMirror].include?(partner_name)
      agent = nil
      ltd_plan_name = nil
      coupon_code_used = @account.coupon_code_used
      if coupon_code_used == 0
        agent = 3
        ltd_plan_name = 'Tier 1'
      elsif coupon_code_used == 1
        agent = 5
        ltd_plan_name = 'Tier 2'
      elsif coupon_code_used == 2
        agent = 15
        ltd_plan_name = 'Tier 3'
      elsif coupon_code_used == 3
        agent = 15
        ltd_plan_name = 'Tier 3'
      elsif coupon_code_used == 4
        agent = 100_000
        ltd_plan_name = 'Tier 4'
      end
      @account.update(
        ltd_attributes: {
          ltd_plan_name: ltd_plan_name,
          ltd_quantity: agent
        },
        limits: {
          agents: agent,
          inboxes: 100_000
        }
      )
      if @account.coupon_code_used < 5
        @account.update(
          coupon_code_used: @account.coupon_code_used + 1
        )
      end

    elsif %w[PitchGround RocketHub DealFuel OneHash].include?(partner_name)
      tier = coupon_code.code[-2, 2]
      agent = nil
      ltd_plan_name = nil
      coupon_code_used = @account.coupon_code_used
      if tier == 'T1'
        agent = 3
        ltd_plan_name = 'Tier 1'
      elsif tier == 'T2'
        agent = 5
        ltd_plan_name = 'Tier 2'
      elsif tier == 'T3'
        agent = 15
        ltd_plan_name = 'Tier 3'
      elsif tier == 'T4'
        agent = 100_000
        ltd_plan_name = 'Tier 4'
      end
      @account.update(
        ltd_attributes: {
          ltd_plan_name: ltd_plan_name,
          ltd_quantity: agent
        },
        limits: {
          agents: agent,
          inboxes: 100_000
        }
      )
      if @account.coupon_code_used < 1
        @account.update(
          coupon_code_used: @account.coupon_code_used + 1
        )
      end
    end
  end
end
