require 'cgi'
require 'uri'

class ZaloOa::AuthClient
  class << self
    # Generate Zalo OA OAuth authorization URL
    #
    # @param state [String] State parameter for CSRF protection
    # @return [String, nil] Authorization URL or nil if client_id is missing
    def authorize_url(state: nil)
      return nil if client_id.blank?

      # Zalo OA OAuth v4 permission flow.
      # Docs on developers.zalo.me sometimes redirect to the portal homepage if the endpoint/params are not correct.
      # We use the OA-specific permission endpoint (v4) instead of the generic v3 auth endpoint.
      params = {
        app_id: client_id,
        redirect_uri: redirect_uri
      }
      params[:state] = state if state.present?

      "https://oauth.zaloapp.com/v4/oa/permission?#{URI.encode_www_form(params)}"
    end

    # Exchange authorization code for access token
    #
    # @param code [String] Authorization code from callback
    # @return [Hash] Token response with oa_id, access_token, refresh_token, expires_in
    def obtain_access_token(code)
      endpoint = 'https://oauth.zaloapp.com/v4/oa/access_token'
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      body = {
        app_id: client_id,
        app_secret: client_secret,
        code: code,
        grant_type: 'authorization_code'
      }

      response = HTTParty.post(
        endpoint,
        body: body,
        headers: headers
      )

      json = process_json_response(response, 'Failed to obtain Zalo OA access token')

      {
        oa_id: json['data']['oa_id'],
        access_token: json['data']['access_token'],
        refresh_token: json['data']['refresh_token'],
        expires_in: json['data']['expires_in']
      }.with_indifferent_access
    end

    private

    def client_id
      GlobalConfigService.load('ZALO_APP_ID', nil)
    end

    def client_secret
      GlobalConfigService.load('ZALO_APP_SECRET', nil)
    end

    def process_json_response(response, error_prefix)
      unless response.success?
        Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
        raise "#{response.code}: #{response.body}"
      end

      json = JSON.parse(response.body)

      # Zalo API returns error_code in response
      if json['error'] && json['error'] != 0
        error_message = json['message'] || 'Unknown error'
        Rails.logger.error "#{error_prefix}. Error: #{json['error']}, Message: #{error_message}"
        raise "#{json['error']}: #{error_message}"
      end

      json
    end

    def redirect_uri
      "#{base_url}/zalo_oa/callback"
    end

    def base_url
      ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    end
  end
end
