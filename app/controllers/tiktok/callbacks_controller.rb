class Tiktok::CallbacksController < ApplicationController
  include Tiktok::IntegrationHelper

  def show
    return handle_authorization_error if params[:error].present?
    return handle_ungranted_scopes_error unless all_scopes_granted?

    process_successful_authorization
  rescue StandardError => e
    handle_error(e)
  end

  private

  def all_scopes_granted?
    granted_scopes = short_term_access_token[:scope].to_s.split(',')
    (Tiktok::AuthClient::REQUIRED_SCOPES - granted_scopes).blank?
  end

  def process_successful_authorization
    inbox, already_exists = find_or_create_inbox

    if already_exists
      redirect_to app_tiktok_inbox_settings_url(account_id: account_id, inbox_id: inbox.id)
    else
      redirect_to app_tiktok_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
    end
  end

  def handle_error(error)
    Rails.logger.error("TikTok Channel creation Error: #{error.message}")
    ChatwootExceptionTracker.new(error).capture_exception

    redirect_to_error_page(error_type: error.class.name, code: 500, error_message: error.message)
  end

  # Handles the case when a user denies permissions or cancels the authorization flow
  def handle_authorization_error
    redirect_to_error_page(
      error_type: params[:error] || 'access_denied',
      code: params[:error_code],
      error_message: params[:error_description] || 'User cancelled the Authorization'
    )
  end

  # Handles the case when a user partially accepted the required scopes
  def handle_ungranted_scopes_error
    redirect_to_error_page(
      error_type: 'ungranted_scopes',
      code: 400,
      error_message: 'User did not grant all the required scopes'
    )
  end

  # Centralized method to redirect to error page with appropriate parameters
  # This ensures consistent error handling across different error scenarios
  # Frontend will handle the error page based on the error_type
  def redirect_to_error_page(error_type:, code:, error_message:)
    redirect_to app_new_tiktok_inbox_url(
      account_id: account_id,
      error_type: error_type,
      code: code,
      error_message: error_message
    )
  end

  def find_or_create_inbox
    business_details = tiktok_client.business_account_details
    channel_tiktok = find_channel
    channel_exists = channel_tiktok.present?

    if channel_tiktok
      update_channel(channel_tiktok, business_details)
    else
      channel_tiktok = create_channel_with_inbox(business_details)
    end

    # reauthorized will also update cache keys for the associated inbox
    channel_tiktok.reauthorized!

    set_avatar(channel_tiktok.inbox, business_details[:profile_image]) if business_details[:profile_image].present?

    [channel_tiktok.inbox, channel_exists]
  end

  def create_channel_with_inbox(business_details)
    ActiveRecord::Base.transaction do
      channel_tiktok = Channel::Tiktok.create!(
        account: account,
        business_id: short_term_access_token[:business_id],
        access_token: short_term_access_token[:access_token],
        refresh_token: short_term_access_token[:refresh_token],
        expires_at: short_term_access_token[:expires_at],
        refresh_token_expires_at: short_term_access_token[:refresh_token_expires_at]
      )

      account.inboxes.create!(
        account: account,
        channel: channel_tiktok,
        name: business_details[:display_name].presence || business_details[:username]
      )

      channel_tiktok
    end
  end

  def find_channel
    Channel::Tiktok.find_by(business_id: short_term_access_token[:business_id], account: account)
  end

  def update_channel(channel_tiktok, business_details)
    channel_tiktok.update!(
      access_token: short_term_access_token[:access_token],
      refresh_token: short_term_access_token[:refresh_token],
      expires_at: short_term_access_token[:expires_at],
      refresh_token_expires_at: short_term_access_token[:refresh_token_expires_at]
    )

    channel_tiktok.inbox.update!(name: business_details[:display_name].presence || business_details[:username])
  end

  def set_avatar(inbox, avatar_url)
    Avatar::AvatarFromUrlJob.perform_later(inbox, avatar_url)
  end

  def account_id
    @account_id ||= verify_tiktok_token(params[:state])
  end

  def account
    @account ||= Account.find(account_id)
  end

  def short_term_access_token
    @short_term_access_token ||= Tiktok::AuthClient.obtain_short_term_access_token(params[:code])
  end

  def tiktok_client
    @tiktok_client ||= Tiktok::Client.new(
      business_id: short_term_access_token[:business_id],
      access_token: short_term_access_token[:access_token]
    )
  end
end
