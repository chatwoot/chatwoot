class ZaloOa::CallbacksController < ApplicationController
  include ZaloOa::IntegrationHelper

  def show
    return handle_authorization_error if params[:error].present?

    process_successful_authorization
  rescue StandardError => e
    handle_error(e)
  end

  private

  def process_successful_authorization
    token_response = ZaloOa::AuthClient.obtain_access_token(params[:code])
    inbox, already_exists = find_or_create_inbox(token_response)

    if already_exists
      redirect_to app_zalo_oa_inbox_settings_url(account_id: account_id, inbox_id: inbox.id)
    else
      redirect_to app_zalo_oa_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
    end
  end

  def handle_error(error)
    Rails.logger.error("Zalo OA Channel creation Error: #{error.message}")
    ChatwootExceptionTracker.new(error).capture_exception

    redirect_to_error_page(
      error_type: error.class.name,
      code: 500,
      error_message: error.message
    )
  end

  def handle_authorization_error
    redirect_to_error_page(
      error_type: params[:error] || 'access_denied',
      code: params[:error_code] || 400,
      error_message: params[:error_description] || 'User cancelled the Authorization'
    )
  end

  def redirect_to_error_page(error_type:, code:, error_message:)
    redirect_to app_new_zalo_oa_inbox_url(
      account_id: account_id,
      error_type: error_type,
      code: code,
      error_message: error_message
    )
  end

  def find_or_create_inbox(token_response)
    oa_id = token_response[:oa_id]
    channel_zalo_oa = find_channel_by_oa_id(oa_id)
    channel_exists = channel_zalo_oa.present?

    if channel_zalo_oa
      update_channel(channel_zalo_oa, token_response)
    else
      channel_zalo_oa = create_channel_with_inbox(token_response)
    end

    # reauthorize channel, this code path only triggers when zalo auth is successful
    channel_zalo_oa.reauthorized! if channel_zalo_oa.respond_to?(:reauthorized!)

    [channel_zalo_oa.inbox, channel_exists]
  end

  def find_channel_by_oa_id(oa_id)
    Channel::ZaloOa.find_by(oa_id: oa_id, account: account)
  end

  def update_channel(channel_zalo_oa, token_response)
    Time.current
    token_response[:expires_in].seconds

    channel_zalo_oa.update!(
      access_token: token_response[:access_token],
      refresh_token: token_response[:refresh_token]
    )

    channel_zalo_oa
  end

  def create_channel_with_inbox(token_response)
    ActiveRecord::Base.transaction do
      Time.current
      token_response[:expires_in].seconds
      oa_id = token_response[:oa_id]

      channel_zalo_oa = Channel::ZaloOa.create!(
        oa_id: oa_id,
        access_token: token_response[:access_token],
        refresh_token: token_response[:refresh_token],
        account: account
      )

      account.inboxes.create!(
        account: account,
        channel: channel_zalo_oa,
        name: "Zalo OA #{oa_id}"
      )

      channel_zalo_oa
    end
  end

  def account_id
    @account_id ||= verify_zalo_token(params[:state])
  end

  def account
    @account ||= Account.find(account_id)
  end
end
