class AppleMessagesForBusiness::Oauth2Service
  def initialize(provider)
    @provider = provider.downcase
  end

  def exchange_code(authorization_code, redirect_uri)
    response = HTTParty.post(
      token_endpoint,
      body: token_request_body(authorization_code, redirect_uri),
      headers: token_request_headers
    )

    if response.success?
      {
        access_token: response.parsed_response['access_token'],
        refresh_token: response.parsed_response['refresh_token'],
        expires_in: response.parsed_response['expires_in'],
        token_type: response.parsed_response['token_type']
      }
    else
      { error: "Token exchange failed: #{response.body}" }
    end
  end

  def fetch_user_data(access_token)
    response = HTTParty.get(
      user_info_endpoint,
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      }
    )

    if response.success?
      normalize_user_data(response.parsed_response)
    else
      { error: "User data fetch failed: #{response.body}" }
    end
  end

  def refresh_token(refresh_token)
    return { error: 'Refresh token not supported' } unless supports_refresh_token?

    response = HTTParty.post(
      token_endpoint,
      body: refresh_token_body(refresh_token),
      headers: token_request_headers
    )

    if response.success?
      {
        access_token: response.parsed_response['access_token'],
        refresh_token: response.parsed_response['refresh_token'] || refresh_token,
        expires_in: response.parsed_response['expires_in']
      }
    else
      { error: "Token refresh failed: #{response.body}" }
    end
  end

  private

  def token_endpoint
    case @provider
    when 'google'
      'https://oauth2.googleapis.com/token'
    when 'linkedin'
      'https://www.linkedin.com/oauth/v2/accessToken'
    when 'facebook'
      'https://graph.facebook.com/v18.0/oauth/access_token'
    else
      raise "Unsupported provider: #{@provider}"
    end
  end

  def user_info_endpoint
    case @provider
    when 'google'
      'https://www.googleapis.com/oauth2/v2/userinfo'
    when 'linkedin'
      'https://api.linkedin.com/v2/people/~:(id,firstName,lastName,emailAddress)'
    when 'facebook'
      'https://graph.facebook.com/me?fields=id,name,email'
    else
      raise "Unsupported provider: #{@provider}"
    end
  end

  def token_request_body(authorization_code, redirect_uri)
    base_params = {
      grant_type: 'authorization_code',
      code: authorization_code,
      redirect_uri: redirect_uri
    }

    case @provider
    when 'google'
      base_params.merge(
        client_id: ENV['GOOGLE_OAUTH_CLIENT_ID'],
        client_secret: ENV['GOOGLE_OAUTH_CLIENT_SECRET']
      )
    when 'linkedin'
      base_params.merge(
        client_id: ENV['LINKEDIN_OAUTH_CLIENT_ID'],
        client_secret: ENV['LINKEDIN_OAUTH_CLIENT_SECRET']
      )
    when 'facebook'
      base_params.merge(
        client_id: ENV['FACEBOOK_OAUTH_CLIENT_ID'],
        client_secret: ENV['FACEBOOK_OAUTH_CLIENT_SECRET']
      )
    end
  end

  def refresh_token_body(refresh_token)
    base_params = {
      grant_type: 'refresh_token',
      refresh_token: refresh_token
    }

    case @provider
    when 'google'
      base_params.merge(
        client_id: ENV['GOOGLE_OAUTH_CLIENT_ID'],
        client_secret: ENV['GOOGLE_OAUTH_CLIENT_SECRET']
      )
    when 'linkedin'
      base_params.merge(
        client_id: ENV['LINKEDIN_OAUTH_CLIENT_ID'],
        client_secret: ENV['LINKEDIN_OAUTH_CLIENT_SECRET']
      )
    end
  end

  def token_request_headers
    case @provider
    when 'linkedin'
      { 'Content-Type' => 'application/x-www-form-urlencoded' }
    else
      { 'Content-Type' => 'application/x-www-form-urlencoded' }
    end
  end

  def normalize_user_data(raw_data)
    case @provider
    when 'google'
      {
        id: raw_data['id'],
        name: raw_data['name'],
        email: raw_data['email'],
        picture: raw_data['picture'],
        provider: 'google'
      }
    when 'linkedin'
      {
        id: raw_data['id'],
        name: "#{raw_data.dig('firstName', 'localized', 'en_US')} #{raw_data.dig('lastName', 'localized', 'en_US')}",
        email: raw_data['emailAddress'],
        provider: 'linkedin'
      }
    when 'facebook'
      {
        id: raw_data['id'],
        name: raw_data['name'],
        email: raw_data['email'],
        provider: 'facebook'
      }
    end
  end

  def supports_refresh_token?
    %w[google linkedin].include?(@provider)
  end
end