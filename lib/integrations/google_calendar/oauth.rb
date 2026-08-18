class Integrations::GoogleCalendar::Oauth
  AUTHORIZE_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
  TOKEN_URL = 'https://oauth2.googleapis.com/token'
  USERINFO_URL = 'https://www.googleapis.com/oauth2/v2/userinfo'
  SCOPE = 'https://www.googleapis.com/auth/calendar openid email profile'
  TIMEOUT = 30

  class << self
    def configured?
      client_id.present? && client_secret.present?
    end

    def client_id
      GlobalConfigService.load('GOOGLE_CALENDAR_CLIENT_ID', nil)
    end

    def client_secret
      GlobalConfigService.load('GOOGLE_CALENDAR_CLIENT_SECRET', nil)
    end

    def redirect_uri
      "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/google_calendar/callback"
    end

    def authorize_url(state)
      params = {
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: 'code',
        scope: SCOPE,
        access_type: 'offline',
        prompt: 'consent',
        state: state
      }
      "#{AUTHORIZE_URL}?#{params.to_query}"
    end

    def exchange_code(code)
      response = HTTParty.post(
        TOKEN_URL,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
        body: {
          code: code,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          grant_type: 'authorization_code'
        },
        timeout: TIMEOUT
      )
      raise "Google token exchange failed: #{response.body}" unless response.success?

      response.parsed_response
    end

    def refresh_access_token(refresh_token)
      response = HTTParty.post(
        TOKEN_URL,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
        body: {
          refresh_token: refresh_token,
          client_id: client_id,
          client_secret: client_secret,
          grant_type: 'refresh_token'
        },
        timeout: TIMEOUT
      )
      raise "Google token refresh failed: #{response.body}" unless response.success?

      response.parsed_response
    end

    def fetch_email(access_token)
      fetch_profile(access_token)[:email]
    end

    def fetch_profile(access_token)
      response = HTTParty.get(
        USERINFO_URL,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        timeout: TIMEOUT
      )
      raise "Google userinfo failed: #{response.body}" unless response.success?

      payload = response.parsed_response || {}
      name = name_from_userinfo(payload)
      { email: payload['email'], name: name }
    end

    def name_from_id_token(id_token)
      return if id_token.blank?

      encoded = id_token.split('.')[1]
      return if encoded.blank?

      padded = encoded + ('=' * ((4 - encoded.length % 4) % 4))
      name_from_userinfo(JSON.parse(Base64.urlsafe_decode64(padded)))
    rescue StandardError
      nil
    end

    private

    def name_from_userinfo(payload)
      payload = payload.with_indifferent_access
      payload['name'].presence || [payload['given_name'], payload['family_name']].compact_blank.join(' ').presence
    end
  end
end
