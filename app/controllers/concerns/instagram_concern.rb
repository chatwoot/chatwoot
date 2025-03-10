module InstagramConcern
  extend ActiveSupport::Concern
  include HTTParty

  def instagram_client
    client_id = ENV.fetch('INSTAGRAM_APP_ID', nil)
    client_secret = ENV.fetch('INSTAGRAM_APP_SECRET', nil)

    Rails.logger.info "Instagram OAuth Setup - Client ID: #{client_id.present? ? 'Present' : 'Missing'}"

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
    response = HTTParty.get(
      'https://graph.instagram.com/access_token',
      query: {
        grant_type: 'ig_exchange_token',
        client_secret: ENV.fetch('INSTAGRAM_APP_SECRET'),
        access_token: short_lived_token,
        client_id: ENV.fetch('INSTAGRAM_APP_ID')
      },
      headers: {
        'Accept' => 'application/json'
      }
    )

    Rails.logger.info "Long-lived token exchange raw response: #{response.inspect}"

    unless response.success?
      Rails.logger.error "Failed to exchange token. Status: #{response.code}, Body: #{response.body}"
      raise "Failed to exchange token: #{response.body}"
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON response: #{response.body}"
      raise e
    end
  end

  def refresh_long_lived_token(long_lived_token)
    response = HTTParty.get(
      'https://graph.instagram.com/refresh_access_token',
      query: {
        grant_type: 'ig_refresh_token',
        access_token: long_lived_token
      },
      headers: {
        'Accept' => 'application/json'
      }
    )

    unless response.success?
      Rails.logger.error "Failed to refresh token. Status: #{response.code}, Body: #{response.body}"
      raise "Failed to refresh token: #{response.body}"
    end

    JSON.parse(response.body)
  end

  def fetch_instagram_user_details(access_token)
    response = HTTParty.get(
      'https://graph.instagram.com/v22.0/me',
      query: {
        fields: 'id,username,user_id,name,profile_picture_url,account_type',
        access_token: access_token
      },
      headers: {
        'Accept' => 'application/json'
      }
    )

    Rails.logger.info "Instagram user details raw response: #{response.inspect}"

    unless response.success?
      Rails.logger.error "Failed to fetch Instagram user details. Status: #{response.code}, Body: #{response.body}"
      raise "Failed to fetch Instagram user details: #{response.body}"
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON response: #{response.body}"
      raise e
    end
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
