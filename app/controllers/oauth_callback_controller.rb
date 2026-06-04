class OauthCallbackController < ApplicationController
  def show
    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback"
    )

    handle_response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to '/'
  end

  private

  def handle_response
    inbox, already_exists = find_or_create_inbox

    return redirect_to app_onboarding_inbox_setup_url(account_id: account.id) if return_to == 'onboarding'

    if already_exists
      redirect_to app_email_inbox_settings_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    end
  end

  def find_or_create_inbox
    channel_email = find_channel_by_email
    # we need this value to know where to redirect on sucessful processing of the callback
    channel_exists = channel_email.present?

    channel_email ||= create_channel_with_inbox
    update_channel(channel_email)

    # reauthorize channel, this code path only triggers when microsoft auth is successful
    # reauthorized will also update cache keys for the associated inbox
    channel_email.reauthorized!

    [channel_email.inbox, channel_exists]
  end

  def find_channel_by_email
    Channel::Email.find_by(email: users_data['email'], account: account)
  end

  def update_channel(channel_email)
    channel_email.update!({
                            imap_login: imap_login_identity, imap_address: imap_address,
                            imap_port: '993', imap_enabled: true,
                            provider: provider_name,
                            provider_config: {
                              access_token: parsed_body['access_token'],
                              refresh_token: parsed_body['refresh_token'],
                              expires_on: (Time.current.utc + 1.hour).to_s
                            }
                          })
  end

  # Identity used as the IMAP/SMTP login (SASL XOAUTH2 `user=` field). Defaults to the
  # id_token's email claim; providers override when their server requires a different
  # claim (e.g. Microsoft SMTP requires UPN).
  def imap_login_identity
    users_data['email']
  end

  def provider_name
    raise NotImplementedError
  end

  def oauth_client
    raise NotImplementedError
  end

  def create_channel_with_inbox
    ActiveRecord::Base.transaction do
      channel_email = Channel::Email.create!(email: users_data['email'], account: account)

      account.inboxes.create!(
        account: account,
        channel: channel_email,
        name: users_data['name'] || fallback_name
      )
      channel_email
    end
  end

  def users_data
    decoded_token = JWT.decode parsed_body[:id_token], nil, false
    decoded_token[0]
  end

  # The sgid purpose carries the onboarding return hint (see
  # OauthAuthorizationController#state). Try the onboarding purpose first — a match
  # both resolves the account and records the return target — then fall back to the
  # default purpose used by every other caller.
  def account_from_signed_id
    raise ActionController::BadRequest, 'Missing state variable' if params[:state].blank?

    if (account = GlobalID::Locator.locate_signed(params[:state], for: 'onboarding'))
      @return_to = 'onboarding'
    else
      account = GlobalID::Locator.locate_signed(params[:state])
    end

    raise 'Invalid or expired state' if account.nil?

    account
  end

  def account
    @account ||= account_from_signed_id
  end

  def return_to
    account # resolving the sgid records which purpose matched
    @return_to
  end

  # Fallback name, for when name field is missing from users_data
  def fallback_name
    users_data['email'].split('@').first.parameterize.titleize
  end

  def oauth_code
    params[:code]
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end
end
