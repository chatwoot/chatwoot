class Api::V1::AccountsController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper

  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :validate_captcha, only: [:create]
  before_action :fetch_account, except: [:create]
  before_action :check_authorization, except: [:create]

  skip_before_action :verify_subscription,
                     only: [:billing_subscription, :show, :change_plan], raise: false
  before_action :fetch_account, except: [:create]
  before_action :check_authorization, except: [:create]

  rescue_from CustomExceptions::Account::InvalidEmail,
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
      @account.check_and_subscribe_for_plan(@user)
      send_auth_headers(@user)
      render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  def cache_keys
    expires_in 10.seconds, public: false, stale_while_revalidate: 5.minutes
    render json: { cache_keys: get_cache_keys }, status: :ok
  end

  def update
    @account.update!(account_params.slice(:name, :locale, :domain, :support_email, :auto_resolve_duration))
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  def billing_subscription
    @billing_subscription = @account.account_billing_subscriptions.last
    @available_product_prices = Enterprise::BillingProductPrice.includes(:billing_product)
    render 'api/v1/models/_billing', format: :json,
                                                   resource: { billing_subscription: @billing_subscription, available_product_prices: @available_product_prices }
  end

  def change_plan
    Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)
    @billing_subscription = Enterprise::BillingProductPrice.find(params[:product_price])
    active_subscription = @account.account_billing_subscriptions.where.not(subscription_stripe_id: nil)&.last
    subscription = Stripe::Subscription.retrieve(active_subscription.subscription_stripe_id) if active_subscription
    url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{@account.id}/settings/billing?subscription_status=success"
    if subscription.present?
      update_subscription(subscription)
    else
      url = @account.create_checkout_link(@billing_subscription)
    end
    render json: { url: url }
  end

  def coupon_code
    code = CouponCode.find_by(code: params[:coupon_code])
    if code && (code.partner == 'AppSumo' || code.partner == 'DealMirror')
      if Time.current > code.expiry_date
        render json: { message: 'Coupon code has expired' }, status: :unprocessable_entity
      elsif code.status == 'redeemed'
        render json: { message: 'Coupon code already used' }, status: :unprocessable_entity
      elsif @account.coupon_code_used >= 5
        render json: { message: 'Account limit reached. Cannot add more coupon codes' }, status: :unprocessable_entity
      else
        @account.subscribe_for_ltd_plan(code)
        code.update!(account_id: @account.id, account_name: @account.name, status: 'redeemed', redeemed_at: Time.current)
        if @account.coupon_code_used == 4
          render json: { message: 'To upgrade to unlimited agents, please apply the fifth code.' }, status: :ok
        else
          render json: { message: 'Redemption successful' }, status: :ok
        end
      end
    elsif code && (code.partner == 'PitchGround')
      if Time.current > code.expiry_date
        render json: { message: 'Coupon code has expired' }, status: :unprocessable_entity
      elsif code.status == 'redeemed'
        render json: { message: 'Coupon code already used' }, status: :unprocessable_entity
      elsif @account.coupon_code_used >= 1
        render json: { message: 'Account limit reached. Cannot add more coupon codes' }, status: :unprocessable_entity
      else
        @account.subscribe_for_ltd_plan(code)
        code.update!(account_id: @account.id, account_name: @account.name, status: 'redeemed', redeemed_at: Time.current)
        render json: { message: 'Redemption successful' }, status: :ok
      end
    else
      render json: { message: 'The provided coupon code is invalid or does not exist' }, status: :unprocessable_entity
    end
  end

  private

  def get_cache_keys
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

  def update_subscription(subscription)
    Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)
    Stripe::Subscription.update(
      subscription.id,
      {
        cancel_at_period_end: false,
        proration_behavior: 'always_invoice',
        items: [
          {
            id: subscription.items.data[0].id,
            price: @billing_subscription.price_stripe_id
          }
        ],
        metadata: {
          account_id: @account.id,
          website: 'OneHash_Chat'
        }
      }
    )
  end
end
