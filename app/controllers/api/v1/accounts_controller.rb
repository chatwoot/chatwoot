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
    features = account_params.delete(:features) || {}
    @user, @account = AccountBuilder.new(…params…).perform

    sync_features!(@account, features)

    send_auth_headers(@user)
    render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
  end

  def cache_keys
    expires_in 10.seconds, public: false, stale_while_revalidate: 5.minutes
    render json: { cache_keys: cache_keys_for_account }, status: :ok
  end

  def update
    features = account_params.delete(:features) || {}

    @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email))
    @account.custom_attributes.merge!(custom_attributes_params)
    @account.settings.merge!(settings_params)
    @account.save!

    sync_features!(@account, features)

    render 'api/v1/accounts/show', format: :json
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  private

  def ensure_account_name
    return if account_params[:account_name].present?
    return if account_params[:user_full_name].present?

    raise CustomExceptions::Account::InvalidParams.new({})
  end

  def cache_keys_for_account
    {
      label: fetch_value_for_key(params[:id], Label.name.underscore),
      inbox: fetch_value_for_key(params[:id], Inbox.name.underscore),
      team:  fetch_value_for_key(params[:id], Team.name.underscore)
    }
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def account_params
    params.permit(
      :account_name,
      :email,
      :name,
      :password,
      :locale,
      :domain,
      :support_email,
      :user_full_name,
      features: {}
    )
  end

  def custom_attributes_params
    params.permit(:industry, :company_size, :timezone)
  end

  def settings_params
    params.permit(:auto_resolve_after, :auto_resolve_message, :auto_resolve_ignore_waiting, :audio_transcriptions, :auto_resolve_label)
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

  def sync_features!(account, incoming_features)
    existing = GlobalConfig.where(account: account).where("key LIKE ?", "feature_%_enabled").pluck(:key)
    existing_names = existing.map { |k| k[/\Afeature_(.*)_enabled\z/, 1] }
    all_names = (existing_names + incoming_features.keys.map(&:to_s)).uniq
    all_names.each do |feature_name|
      enabled = ActiveModel::Type::Boolean.new.cast(incoming_features[feature_name])
      config_key = "feature_#{feature_name}_enabled"
      config     = GlobalConfig.find_or_initialize_by(account: account, key: config_key)
      if enabled
        config.value = "true"
        config.save!
      else
        config.destroy if config.persisted?
      end
    rescue StandardError => e
      Rails.logger.error("Erro ao sincronizar feature '#{feature_name}': #{e.message}")
    end
  end

end
