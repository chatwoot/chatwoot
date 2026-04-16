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
      user: current_user
    ).perform
    enqueue_branding_enrichment
    if @user
      # Authenticated users (dashboard "add account") and api_only signups
      # need the full response with account_id. API-only deployments have no
      # frontend to handle the email confirmation flow, so they need auth
      # tokens to proceed.
      # Unauthenticated web signup returns only the email — no session is
      # created until the user confirms via the email link.
      if current_user || api_only_signup?
        send_auth_headers(@user)
        render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
      else
        render json: { email: @user.email }
      end
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  def cache_keys
    expires_in 10.seconds, public: false, stale_while_revalidate: 5.minutes
    render json: { cache_keys: cache_keys_for_account }, status: :ok
  end

  def update
    @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email))
    @account.custom_attributes.merge!(custom_attributes_params)
    @account.settings.merge!(settings_params)
    @account.custom_attributes['onboarding_step'] = 'invite_team' if @account.custom_attributes['onboarding_step'] == 'account_update'
    @account.save!
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  private

  def enqueue_branding_enrichment
    return if account_params[:email].blank?

    Account::BrandingEnrichmentJob.perform_later(@account.id, account_params[:email])
    Redis::Alfred.set(format(Redis::Alfred::ACCOUNT_ONBOARDING_ENRICHMENT, account_id: @account.id), '1', ex: 30)
  rescue StandardError => e
    # Enrichment is optional — never let queue/Redis failures abort signup
    ChatwootExceptionTracker.new(e).capture_exception
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
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :user_full_name)
  end

  def custom_attributes_params
    params.permit(:industry, :company_size, :timezone)
  end

  def settings_params
    params.permit(*permitted_settings_attributes)
  end

  def permitted_settings_attributes
    [:auto_resolve_after, :auto_resolve_message, :auto_resolve_ignore_waiting, :audio_transcriptions, :auto_resolve_label]
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' unless GlobalConfigService.account_signup_enabled?
  end

  def api_only_signup?
    # CW_API_ONLY_SERVER is the canonical flag for API-only deployments.
    # ENABLE_ACCOUNT_SIGNUP='api_only' is a legacy sentinel for the same purpose.
    # Read ENABLE_ACCOUNT_SIGNUP raw from InstallationConfig because GlobalConfig.get
    # typecasts it to boolean, coercing 'api_only' to true.
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) ||
      InstallationConfig.find_by(name: 'ENABLE_ACCOUNT_SIGNUP')&.value.to_s == 'api_only'
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

Api::V1::AccountsController.prepend_mod_with('Api::V1::AccountsSettings')
