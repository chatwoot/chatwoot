class Api::V1::AccountsController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper
  include Shopify::IntegrationHelper

  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :ensure_account_name, only: [:create]
  before_action :validate_captcha, only: [:create]
  before_action :verify_shopify_hmac, only: [:create]
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
    # Check if shop already exists (only for Shopify signups)
    if account_params[:shop].present?
      existing_store = Dashassist::ShopifyStore.find_by(shop: account_params[:shop])
      
      if existing_store
        Rails.logger.error("[Shopify Store] Shop #{account_params[:shop]} is already registered")
        return render json: { error: 'This shop is already registered with another account' }, status: :unprocessable_entity
      end
    end

    user = nil
    account = nil
    
    ActiveRecord::Base.transaction do
      @user, @account = AccountBuilder.new(
        account_name: account_params[:account_name],
        user_full_name: account_params[:user_full_name],
        email: account_params[:email],
        user_password: account_params[:password],
        locale: account_params[:locale],
        user: current_user
      ).perform
    end

    user = @user
    account = @account

    # Move Shopify integration outside of transaction
    if account_params[:shop].present? && user && account
      # Use the ShopifyInboxCreatorService to create all Shopify resources
      ShopifyInboxCreatorService.new(user, account_params[:shop]).setup_shopify_integration_for_account(account)
    end

    if user
      send_auth_headers(user)
      render 'api/v1/accounts/create', format: :json, locals: { resource: user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  rescue CustomExceptions::Account::InvalidParams => e
    Rails.logger.error("[Account Creation] #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
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
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :auto_resolve_duration, :user_full_name, :shop)
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

  def verify_shopify_hmac
    # Only verify HMAC if this is a Shopify installation request
    return unless params[:shop].present? && params[:hmac].present? && params[:timestamp].present?
    
    Rails.logger.info("[Shopify Accounts] Verifying HMAC for shop: #{params[:shop]}")
    
    # Get all query parameters
    query_params = request.query_parameters
    
    # Verify the HMAC signature
    unless verify_shopify_installation_hmac(query_params, params[:hmac])
      Rails.logger.error("[Shopify Accounts] Invalid HMAC for shop: #{params[:shop]}")
      raise ActionController::InvalidAuthenticityToken, 'Invalid Shopify HMAC signature'
    end
    
    Rails.logger.info("[Shopify Accounts] HMAC verification successful for shop: #{params[:shop]}")
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
