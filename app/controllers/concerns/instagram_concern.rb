module InstagramConcern
  extend ActiveSupport::Concern
  include HTTParty

  def instagram_client
    client_id = GlobalConfigService.load('INSTAGRAM_APP_ID', nil)
    client_secret = GlobalConfigService.load('INSTAGRAM_APP_SECRET', nil)

    ::OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: 'https://api.instagram.com',
        authorize_url: 'https://api.instagram.com/oauth/authorize',
        token_url: 'https://api.instagram.com/oauth/access_token',
        auth_scheme: :request_body,
        token_method: :post
      }
    )
  end

  private

  def exchange_for_long_lived_token(short_lived_token)
    endpoint = 'https://graph.instagram.com/access_token'
    params = {
      grant_type: 'ig_exchange_token',
      client_secret: GlobalConfigService.load('INSTAGRAM_APP_SECRET', nil),
      access_token: short_lived_token,
      client_id: GlobalConfigService.load('INSTAGRAM_APP_ID', nil)
    }

    make_api_request(endpoint, params, 'Failed to exchange token')
  end

  def refresh_long_lived_token(long_lived_token)
    endpoint = 'https://graph.instagram.com/refresh_access_token'
    params = {
      grant_type: 'ig_refresh_token',
      access_token: long_lived_token
    }

    make_api_request(endpoint, params, 'Failed to refresh token')
  end

  def fetch_instagram_user_details(access_token)
    endpoint = 'https://graph.instagram.com/v22.0/me'
    params = {
      fields: 'id,username,user_id,name,profile_picture_url,account_type',
      access_token: access_token
    }

    make_api_request(endpoint, params, 'Failed to fetch Instagram user details')
  end

  def make_api_request(endpoint, params, error_prefix)
    response = HTTParty.get(
      endpoint,
      query: params,
      headers: { 'Accept' => 'application/json' }
    )

    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{error_prefix}: #{response.body}"
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      ChatwootExceptionTracker.new(e).capture_exception
      Rails.logger.error "Invalid JSON response: #{response.body}"
      raise e
    end
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
