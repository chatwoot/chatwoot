class GooglePlay::CallbacksController < ApplicationController
  include GooglePlayOauthConcern

  def show
    return redirect_with_error(params[:error]) if params[:error].present?

    account
    token = google_client.auth_code.get_token(params[:code], redirect_uri: google_play_callback_url)
    inbox = create_channel_with_inbox(token)

    redirect_to app_google_play_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_with_error(e.message)
  end

  private

  # Sends the user back to the inbox setup form with the error surfaced as a query param.
  # Falls back to '/' only when we can't determine the account (e.g. tampered/missing state).
  def redirect_with_error(error_message)
    acc = safe_account
    return redirect_to '/' unless acc

    redirect_to app_new_google_play_inbox_url(account_id: acc.id, error: error_message.to_s.truncate(300))
  end

  def safe_account
    Account.find_by(id: state_payload[:account_id])
  rescue StandardError
    nil
  end

  def state_payload
    @state_payload ||= google_play_verifier.verify(params[:state]).with_indifferent_access
  end

  def account
    @account ||= Account.find(state_payload[:account_id])
  end

  def create_channel_with_inbox(token)
    ActiveRecord::Base.transaction do
      channel = Channel::GooglePlay.create!(
        account: account,
        app_id: state_payload[:app_id],
        provider_config: {
          access_token: token.token,
          refresh_token: token.refresh_token,
          expires_on: (Time.current.utc + 1.hour).to_s
        }
      )
      # Return the newly created inbox directly — `channel.inbox` is unreliable here because the polymorphic
      # has_one cache is not always populated by `account.inboxes.create!`.
      account.inboxes.create!(account: account, channel: channel, name: state_payload[:inbox_name])
    end
  end
end
