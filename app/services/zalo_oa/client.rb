class ZaloOa::Client
  class Error < StandardError; end

  OAUTH_BASE = 'https://oauth.zaloapp.com/v4/oa'.freeze
  API_BASE = 'https://openapi.zalo.me'.freeze

  class << self
    def permission_url(app_id:, redirect_uri:, state:)
      query = { app_id: app_id, redirect_uri: redirect_uri, state: state }.to_query
      "#{OAUTH_BASE}/permission?#{query}"
    end

    def exchange_code(app_id:, app_secret:, code:)
      request_token(app_secret, app_id: app_id, grant_type: 'authorization_code', code: code)
    end

    def refresh_token(app_id:, app_secret:, refresh_token:)
      request_token(app_secret, app_id: app_id, grant_type: 'refresh_token', refresh_token: refresh_token)
    end

    def fetch_oa_profile(access_token)
      body = get("#{API_BASE}/v2.0/oa/getoa", access_token)
      oa_id = body.dig('data', 'oa_id')
      raise Error, "getoa failed: #{body['error']} #{body['message']}".strip if oa_id.blank?

      { oa_id: oa_id.to_s, name: body.dig('data', 'name').presence }
    end

    def fetch_user_profile(access_token, user_id)
      body = get("#{API_BASE}/v3.0/oa/user/detail", access_token, data: { user_id: user_id }.to_json)
      data = body['data']
      return nil if data.blank? || data['display_name'].blank?

      { name: data['display_name'].to_s, avatar_url: data['avatar'].presence }
    end

    private

    # The app secret travels in a `secret_key` header, not the form body.
    def request_token(app_secret, fields)
      response = HTTParty.post(
        "#{OAUTH_BASE}/access_token",
        headers: { 'secret_key' => app_secret, 'Content-Type' => 'application/x-www-form-urlencoded' },
        body: URI.encode_www_form(fields)
      )
      body = response.parsed_response
      raise Error, "token request failed: #{body.try(:[], 'error')} #{body.try(:[], 'message')}".strip if body.try(:[], 'access_token').blank?

      {
        access_token: body['access_token'],
        refresh_token: body['refresh_token'],
        expires_in: body.fetch('expires_in', 3600).to_i
      }
    end

    def get(url, access_token, query = {})
      response = HTTParty.get(url, headers: { 'access_token' => access_token }, query: query)
      raise Error, "request to #{url} failed with status #{response.code}" unless response.success?

      response.parsed_response
    end
  end
end
