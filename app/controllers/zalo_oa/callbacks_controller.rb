class ZaloOa::CallbacksController < ApplicationController
  def show
    raw = ::Redis::Alfred.get(cache_key)
    pending = raw.present? ? JSON.parse(raw).with_indifferent_access : nil
    # Capture the account before any early return so error redirects land on the right account.
    @account_id = pending[:account_id] if pending.present?
    return redirect_to_dashboard_with_error if pending.blank? || params[:code].blank?

    ::Redis::Alfred.delete(cache_key)
    inbox = build_inbox(pending)
    redirect_to app_zalo_oa_inbox_agents_url(account_id: @account_id, inbox_id: inbox.id)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to_dashboard_with_error
  end

  private

  def build_inbox(pending)
    tokens = ZaloOa::Client.exchange_code(app_id: pending[:app_id], app_secret: pending[:app_secret], code: params[:code])
    profile = ZaloOa::Client.fetch_oa_profile(tokens[:access_token])
    account = Account.find(pending[:account_id])

    ActiveRecord::Base.transaction do
      channel = account.zalo_oa_channels.create!(channel_attributes(pending, tokens, profile))
      account.inboxes.create!(name: profile[:name].presence || channel.name, channel: channel)
    end
  end

  def channel_attributes(pending, tokens, profile)
    {
      oa_id: profile[:oa_id],
      oa_name: profile[:name],
      app_id: pending[:app_id],
      app_secret: pending[:app_secret],
      oa_secret_key: pending[:oa_secret_key],
      access_token: tokens[:access_token],
      refresh_token: tokens[:refresh_token],
      token_expires_at: Time.current + tokens[:expires_in].seconds
    }
  end

  def cache_key
    "zalo_oa:pending:#{params[:state]}"
  end

  def redirect_to_dashboard_with_error
    return redirect_to '/app' if @account_id.blank?

    redirect_to "/app/accounts/#{@account_id}/settings/inboxes/new"
  end
end
