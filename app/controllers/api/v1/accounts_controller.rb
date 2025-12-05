class Api::V1::AccountsController < Api::BaseController # rubocop:disable Metrics/ClassLength
  include AuthHelper
  include CacheKeysHelper
  include BspdAccessHelper

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
    @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email, :auto_resolve_duration))

    # Merge custom attributes
    new_attributes = custom_attributes_params
    if new_attributes[:calling_settings].present?
      existing_settings = @account.custom_attributes['calling_settings'] || {}
      new_attributes[:calling_settings] = existing_settings.merge(new_attributes[:calling_settings])
    end
    @account.custom_attributes.merge!(new_attributes)

    @account.custom_attributes['onboarding_step'] = 'invite_team' if @account.custom_attributes['onboarding_step'] == 'account_update'

    # Update Instagram DM message settings
    return if params[:instagram_dm_message].present? && !update_instagram_settings

    @account.save!
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  def clear_billing_cache
    clear_cache(params[:id])
    head :ok
  end

  def unassigned_conversations_assignment
    inbox_ids = params[:inbox_ids]
    begin
      inbox_ids.each do |inbox_id|
        UnassignedConversationsAssignmentJob.perform_later(inbox_id)
      end
      render json: { success: true }, status: :ok
    rescue StandardError => e
      Rails.logger.error("Error in unassigned_conversations_assignment: #{e.message}")
      render json: { error: 'An error occurred while processing the request' }, status: :internal_server_error
    end
  end

  def create_one_click_conversations
    result = Accounts::OneClickConversationsCreator.new(@account, @user, params).perform
    if result[:success]
      render json: { success: true }, status: :ok
    else
      render json: { error: result[:error] }, status: :internal_server_error
    end
  end

  def create_instagram_dm_conversations
    result = Accounts::InstagramDmConversationsCreator.new(@account, @user, params).perform
    if result[:success]
      render json: { success: true }, status: :ok
    else
      render json: { error: result[:error] }, status: :internal_server_error
    end
  end

  def bulk_import_contacts
    contacts_params = params.require(:contacts)

    batch_size = 1000

    # Validate basic structure of the request
    unless contacts_params.is_a?(Array)
      render json: { error: 'Contacts must be an array' }, status: :bad_request
      return
    end

    # Process in batches of 10
    contacts_params.each_slice(batch_size) do |batch|
      processed_batch = batch.map { |contact| contact.permit(:name, :email, :phone_number).to_h }
      Contacts::BulkImportJob.perform_later(processed_batch, @account.id)
    end

    render json: {
      message: 'Import jobs queued successfully',
      total_contacts: contacts_params.size,
      total_batches: (contacts_params.size / batch_size).ceil
    }, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  def delete_messages_with_source_id
    if params[:source_id].blank? || params[:id].blank?
      render json: { error: 'Source ID and Account ID are required' }, status: :bad_request
      return
    end
    messages = Message.where(account_id: params[:id], source_id: params[:source_id])
    if messages.empty?
      render json: { error: 'Message not found' }, status: :not_found
    else
      ActiveRecord::Base.transaction do
        messages.each do |message|
          message.attachments.destroy_all
          message.destroy
        end
      end
      render json: { success: true }, status: :ok
    end
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
    params.permit(
      :industry,
      :company_size,
      :timezone,
      :enable_contact_assignment,
      :enable_timed_contact_ownership,
      :contact_ownership_duration_minutes,
      calling_settings: {}
    ).to_h.compact
  end

  def update_instagram_settings
    unless @account.instagram_inbox?
      render json: { error: 'Instagram inbox not found for this account' }, status: :forbidden
      return false
    end

    message = params[:instagram_dm_message].to_s.strip
    if message.length > 200
      render json: { error: 'Instagram DM message must be 200 characters or less' }, status: :unprocessable_entity
      return false
    end

    @account.instagram_dm_message = message
    true
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
