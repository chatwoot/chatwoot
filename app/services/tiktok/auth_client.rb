class Tiktok::AuthClient
  REQUIRED_SCOPES = %w[user.info.basic user.info.username user.info.stats user.info.profile user.account.type user.insights message.list.read
                       message.list.send message.list.manage].freeze

  class << self
    def authorize_url(state: nil)
      tiktok_client = ::OAuth2::Client.new(
        client_id,
        client_secret,
        {
          site: 'https://www.tiktok.com',
          authorize_url: '/v2/auth/authorize',
          auth_scheme: :basic_auth
        }
      )

      tiktok_client.authorize_url(
        {
          response_type: 'code',
          client_key: client_id,
          redirect_uri: redirect_uri,
          scope: REQUIRED_SCOPES.join(','),
          state: state
        }
      )
    end

    # https://business-api.tiktok.com/portal/docs?id=1832184159540418
    def obtain_short_term_access_token(auth_code) # rubocop:disable Metrics/MethodLength
      endpoint = 'https://business-api.tiktok.com/open_api/v1.3/tt_user/oauth2/token/'
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      body = {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'authorization_code',
        auth_code: auth_code,
        redirect_uri: redirect_uri
      }

      response = HTTParty.post(
        endpoint,
        body: body.to_json,
        headers: headers
      )

      json = process_json_response(response, 'Failed to obtain TikTok short-term access token')

      {
        business_id: json['data']['open_id'],
        scope: json['data']['scope'],
        access_token: json['data']['access_token'],
        refresh_token: json['data']['refresh_token'],
        expires_at: Time.current + json['data']['expires_in'].seconds,
        refresh_token_expires_at: Time.current + json['data']['refresh_token_expires_in'].seconds
      }.with_indifferent_access
    end

    def renew_short_term_access_token(refresh_token) # rubocop:disable Metrics/MethodLength
      endpoint = 'https://business-api.tiktok.com/open_api/v1.3/tt_user/oauth2/refresh_token/'
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      body = {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'refresh_token',
        refresh_token: refresh_token
      }

      response = HTTParty.post(
        endpoint,
        body: body.to_json,
        headers: headers
      )

      json = process_json_response(response, 'Failed to renew TikTok short-term access token')

      {
        access_token: json['data']['access_token'],
        refresh_token: json['data']['refresh_token'],
        expires_at: Time.current + json['data']['expires_in'].seconds,
        refresh_token_expires_at: Time.current + json['data']['refresh_token_expires_in'].seconds
      }.with_indifferent_access
    end

    def webhook_callback
      endpoint = 'https://business-api.tiktok.com/open_api/v1.3/business/webhook/list/'
      headers = { Accept: 'application/json' }
      params = {
        app_id: client_id,
        secret: client_secret,
        event_type: 'DIRECT_MESSAGE'
      }
      response = HTTParty.get(endpoint, query: params, headers: headers)

      process_json_response(response, 'Failed to fetch TikTok webhook callback')
    end

    def update_webhook_callback
      endpoint = 'https://business-api.tiktok.com/open_api/v1.3/business/webhook/update/'
      headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
      body = {
        app_id: client_id,
        secret: client_secret,
        event_type: 'DIRECT_MESSAGE',
        callback_url: webhook_url
      }
      response = HTTParty.post(endpoint, body: body.to_json, headers: headers)

      process_json_response(response, 'Failed to update TikTok webhook callback')
    end

    private

    def client_id
      GlobalConfigService.load('TIKTOK_APP_ID', nil)
    end

    def client_secret
      GlobalConfigService.load('TIKTOK_APP_SECRET', nil)
    end

    def process_json_response(response, error_prefix)
      unless response.success?
        Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
        raise "#{response.code}: #{response.body}"
      end

      res = JSON.parse(response.body)
      raise "#{res['code']}: #{res['message']}" if res['code'] != 0

      res
    end

    def redirect_uri
      "#{base_url}/tiktok/callback"
    end

    def webhook_url
      "#{base_url}/webhooks/tiktok"
    end

    def base_url
      ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    end
  end
end
