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
    ActiveRecord::Base.transaction do
      @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email, :pinecone_index))
      @account.custom_attributes.merge!(custom_attributes_params)
      @account.settings.merge!(settings_params)
      @account.custom_attributes['onboarding_step'] = 'invite_team' if @account.custom_attributes['onboarding_step'] == 'account_update'
      update_account_address if account_address_params.present? && administrator?
      update_business_hours if business_hours_params.present? && administrator?
      @account.save!
    end
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
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :user_full_name, :pinecone_index)
  end

  def custom_attributes_params
    params.permit(:industry, :company_size, :timezone)
  end

  def settings_params
    params.permit(:auto_resolve_after, :auto_resolve_message, :auto_resolve_ignore_waiting, :audio_transcriptions, :auto_resolve_label,
                  :business_hours_enabled, :business_hours_timezone, conversation_required_attributes: [])
  end

  def account_address_params
    params.permit(account_address: %i[id street exterior_number interior_number neighborhood postal_code city state email phone webpage
                                      establishment_summary])[:account_address]
  end

  def update_account_address
    address_id = account_address_params[:id]
    address_attrs = account_address_params.except(:id)

    if address_id.present?
      address = @account.account_addresses.find_by(id: address_id)
      address ? address.update!(address_attrs) : @account.account_addresses.create!(address_attrs)
    else
      @account.account_addresses.create!(address_attrs)
    end
  end

  def business_hours_params
    params.permit(business_hours: %i[day_of_week open_hour open_minutes close_hour close_minutes closed_all_day open_all_day])[:business_hours]
  end

  def update_business_hours
    return unless business_hours_params.present?

    business_hours_params.each do |day_hours|
      wh = @account.business_working_hours.find_or_initialize_by(day_of_week: day_hours[:day_of_week])
      wh.assign_attributes(day_hours.except(:day_of_week))
      wh.save!
    end
  end

  def administrator?
    @current_account_user&.administrator?
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

Api::V1::AccountsController.prepend_mod_with('Api::V1::AccountsSettings')
