class Api::V1::Accounts::Channels::ZaloChannelsController < Api::V1::Accounts::BaseController
  def create
    oa_id = params[:oa_id]
    access_token = params[:access_token]
    refresh_token = params[:refresh_token]
    expires_in = params[:expires_in]
    inbox_name = params[:inbox_name]
    avatar_url = params[:avatar_url]
    zalo_inbox = nil

    ActiveRecord::Base.transaction do
      channel = Current.account.zalo_oas.create!(oa_id: oa_id, oa_access_token: access_token, refresh_token: refresh_token, expires_in: expires_in)
      zalo_inbox = Current.account.inboxes.create!(name: inbox_name, channel: channel)
      Avatar::AvatarFromUrlJob.perform_later(zalo_inbox, avatar_url)
    end
    render json: zalo_inbox.as_json
  rescue StandardError => e
    handle_exception(e)
  end

  def secret_key
    render json: { secret_key: ENV.fetch('ZALO_APP_SECRET', nil) }
  end

  private

  def handle_exception(exception)
    ChatwootExceptionTracker.new(exception).capture_exception
    Rails.logger.error "Error in create inbox for zalo oa channel: #{exception.message}"
    log_additional_info
  end

  def log_additional_info
    Rails.logger.debug do
      "oa_id: #{params[:oa_id]}, inbox_name: #{params[:inbox_name]} ,
      oa_access_token: #{params[:access_token]} , refresh_token: #{params[:refresh_token]} , expires_in: #{params[:expires_in]}"
    end
  end
end
