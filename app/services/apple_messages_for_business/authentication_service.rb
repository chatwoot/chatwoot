class AppleMessagesForBusiness::AuthenticationService
  include ApplicationHelper

  def initialize(channel)
    @channel = channel
    @key_pair_service = AppleMessagesForBusiness::KeyPairService.instance
  end

  def create_authentication_request(oauth2_provider, redirect_uri, state = nil)
    key_pair = @key_pair_service.get_key_pair(@channel.id)
    auth_state = state || SecureRandom.hex(32)

    request_data = {
      oauth2: {
        scope: oauth2_scopes_for_provider(oauth2_provider),
        state: auth_state,
        response_type: 'code',
        code_challenge_method: 'S256',
        code_challenge: generate_code_challenge
      },
      response_encryption_key: key_pair[:public_key],
      redirect_uri: redirect_uri
    }

    # Store authentication session
    store_auth_session(auth_state, oauth2_provider, key_pair[:key_id])

    request_data
  end

  def process_oauth2_callback(code, state, provider)
    auth_session = get_auth_session(state)
    return { error: 'Invalid state parameter' } unless auth_session

    token_response = exchange_code_for_token(code, provider, auth_session)
    return token_response if token_response[:error]

    user_data = fetch_user_data(token_response[:access_token], provider)
    return user_data if user_data[:error]

    # Create authenticated user response
    {
      success: true,
      user: user_data,
      provider: provider,
      access_token: token_response[:access_token],
      authenticated_at: Time.current
    }
  end

  def generate_landing_page_url(oauth2_provider, success_url, cancel_url = nil)
    state = SecureRandom.hex(32)
    redirect_uri = build_redirect_uri(state)

    auth_request = create_authentication_request(oauth2_provider, redirect_uri, state)

    # Store landing page context
    store_landing_context(state, success_url, cancel_url)

    case oauth2_provider.downcase
    when 'google'
      build_google_oauth_url(auth_request, redirect_uri)
    when 'linkedin'
      build_linkedin_oauth_url(auth_request, redirect_uri)
    when 'facebook'
      build_facebook_oauth_url(auth_request, redirect_uri)
    else
      { error: 'Unsupported OAuth2 provider' }
    end
  end

  private

  def oauth2_scopes_for_provider(provider)
    case provider.downcase
    when 'google'
      ['openid', 'profile', 'email']
    when 'linkedin'
      ['r_liteprofile', 'r_emailaddress']
    when 'facebook'
      ['public_profile', 'email']
    else
      ['profile', 'email']
    end
  end

  def generate_code_challenge
    verifier = SecureRandom.urlsafe_base64(32)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier)).tr('=', '')

    store_code_verifier(verifier)
    challenge
  end

  def store_auth_session(state, provider, key_id)
    auth_sessions = @channel.auth_sessions || {}
    auth_sessions[state] = {
      provider: provider,
      key_id: key_id,
      created_at: Time.current.to_i,
      expires_at: 1.hour.from_now.to_i
    }

    @channel.update!(auth_sessions: auth_sessions)
  end

  def get_auth_session(state)
    auth_sessions = @channel.auth_sessions || {}
    session = auth_sessions[state]

    return nil unless session
    return nil if Time.current.to_i > session['expires_at']

    session
  end

  def store_landing_context(state, success_url, cancel_url)
    # Store in Redis for temporary access
    Redis.current.setex(
      "apple_auth_landing:#{state}",
      3600, # 1 hour
      {
        success_url: success_url,
        cancel_url: cancel_url,
        channel_id: @channel.id
      }.to_json
    )
  end

  def store_code_verifier(verifier)
    # Store temporarily for PKCE verification
    @code_verifier = verifier
  end

  def build_redirect_uri(state)
    Rails.application.routes.url_helpers.apple_messages_oauth_callback_url(
      msp_id: @channel.msp_id,
      state: state,
      host: ENV.fetch('FRONTEND_URL', 'localhost:3000')
    )
  end

  def exchange_code_for_token(code, provider, auth_session)
    oauth2_service = AppleMessagesForBusiness::Oauth2Service.new(provider)
    oauth2_service.exchange_code(code, build_redirect_uri(auth_session['state']))
  rescue StandardError => e
    { error: "Token exchange failed: #{e.message}" }
  end

  def fetch_user_data(access_token, provider)
    oauth2_service = AppleMessagesForBusiness::Oauth2Service.new(provider)
    oauth2_service.fetch_user_data(access_token)
  rescue StandardError => e
    { error: "User data fetch failed: #{e.message}" }
  end

  def build_google_oauth_url(auth_request, redirect_uri)
    params = {
      client_id: ENV['GOOGLE_OAUTH_CLIENT_ID'],
      response_type: 'code',
      scope: auth_request[:oauth2][:scope].join(' '),
      redirect_uri: redirect_uri,
      state: auth_request[:oauth2][:state],
      code_challenge: auth_request[:oauth2][:code_challenge],
      code_challenge_method: 'S256'
    }

    "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}"
  end

  def build_linkedin_oauth_url(auth_request, redirect_uri)
    params = {
      client_id: ENV['LINKEDIN_OAUTH_CLIENT_ID'],
      response_type: 'code',
      scope: auth_request[:oauth2][:scope].join(' '),
      redirect_uri: redirect_uri,
      state: auth_request[:oauth2][:state]
    }

    "https://www.linkedin.com/oauth/v2/authorization?#{params.to_query}"
  end

  def build_facebook_oauth_url(auth_request, redirect_uri)
    params = {
      client_id: ENV['FACEBOOK_OAUTH_CLIENT_ID'],
      response_type: 'code',
      scope: auth_request[:oauth2][:scope].join(','),
      redirect_uri: redirect_uri,
      state: auth_request[:oauth2][:state]
    }

    "https://www.facebook.com/v18.0/dialog/oauth?#{params.to_query}"
  end
end