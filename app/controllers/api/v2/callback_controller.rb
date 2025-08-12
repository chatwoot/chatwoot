class Api::V2::CallbackController < ApplicationController
  def index
    Rails.logger.info '=== Google OAuth Callback Debug ==='
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Authorization Code: #{params[:code]}"
    Rails.logger.info "State: #{params[:state]}"

    begin
      account_id = extract_account_id_from_state(params[:state])

      # Exchange code for token
      access_token = exchange_code_for_token(params[:code],account_id)
      Rails.logger.info "Token exchange successful: #{access_token.present?}"

      # Store user token
      # store_user_token(access_token, account_id)
      Rails.logger.info 'Token storage successful'

      # BARU: Buat spreadsheet setelah token berhasil disimpan
      # spreadsheet_result = create_initial_spreadsheet(access_token['access_token'])
      # Rails.logger.info "Spreadsheet creation result: #{spreadsheet_result.inspect}"

      # Send tokens to external API
      send_tokens_to_external_api(access_token, account_id)

      # DIPERBAIKI: Redirect ke frontend dengan parameter sukses
      frontend_url = "#{request.base_url}/app/accounts/#{account_id}/ai-agents"
      redirect_url = "#{frontend_url}?google_auth_success=true&tab=2"

      Rails.logger.info "Redirecting to: #{redirect_url}"
      redirect_to redirect_url, allow_other_host: true
    rescue StandardError => e
      Rails.logger.error("Google OAuth callback error: #{e.message}")
      Rails.logger.error("Error backtrace: #{e.backtrace.first(5).join('\n')}")

      # Redirect dengan error
      frontend_url = "#{request.base_url}/app/accounts/#{account_id}/ai-agents"
      redirect_url = "#{frontend_url}?google_auth_error=true&error=#{CGI.escape(e.message)}&tab=2"
      redirect_to redirect_url, allow_other_host: true
    end
  end
  def exchange_code_for_token(code, account_id)
    require 'net/http'
    require 'json'

    Rails.logger.info '=== Exchange Code for Token ==='
    Rails.logger.info "Code: #{code}"
    Rails.logger.info "Account ID from params: #{account_id}"

    uri = URI('https://oauth2.googleapis.com/token')
    token_params = {
      client_id: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil),
      client_secret: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil),
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: "#{request.base_url}/api/v2/callback"
    }

    Rails.logger.info "Redirect URI: #{token_params[:redirect_uri]}"
    Rails.logger.info "Client ID: #{token_params[:client_id]}"

    response = Net::HTTP.post_form(uri, token_params)
    Rails.logger.info "Google token response code: #{response.code}"
    Rails.logger.info "Google token response body: #{response.body}"

    raise StandardError, "Failed to exchange code for tokens: #{response.body}" unless response.code == '200'

    JSON.parse(response.body)
  end

  def extract_account_id_from_state(state)
    # Decode and parse the state parameter
    decoded_json = Base64.urlsafe_decode64(state)
    state_data = JSON.parse(decoded_json)

    # Extract the account_id
    account_id = state_data['account_id']

    Rails.logger.info "Decoded state: #{state_data.inspect}"

    account_id
  rescue StandardError => e
    Rails.logger.error "Failed to decode state: #{e.message}"
    raise # Re-raises the current exception
  end

  def send_tokens_to_external_api(access_token, account_id)
    require 'net/http'
    require 'json'

    api_endpoint = GlobalConfigService.load('EXTERNAL_TOKEN_API_URL', nil)
    return if api_endpoint.blank?

    begin
      api_url = URI.parse(api_endpoint)
      http = Net::HTTP.new(api_url.host, api_url.port)
      http.use_ssl = (api_url.scheme == 'https')

      request = Net::HTTP::Post.new(api_url.request_uri, { 'Content-Type' => 'application/json' })
      payload = {
        access_token: access_token['access_token'],
        refresh_token: access_token['refresh_token'],
        account_id: account_id
      }
      request.body = payload.to_json

      response = http.request(request)
      Rails.logger.info "External API response: #{response.code} - #{response.body}"
    rescue StandardError => e
      Rails.logger.error "Failed to send tokens to external API: #{e.message}"
    end
  end
  # def store_user_token(token_data, account_id)
  #   # Get user email from Google
  #   user_info = get_google_user_info(token_data['access_token'])

  #   cache_data = {
  #     'access_token' => token_data['access_token'],
  #     'refresh_token' => token_data['refresh_token'],
  #     'expires_at' => Time.current.to_i + token_data['expires_in'].to_i,
  #     'email' => user_info['email']
  #   }

  #   # Store token for account since we don't have user context in callback
  #   # write_token_to_file(account_id, cache_data)
  # end
  # def get_google_user_info(access_token)
  #   require 'net/http'
  #   require 'json'

  #   uri = URI('https://www.googleapis.com/oauth2/v2/userinfo')
  #   http = Net::HTTP.new(uri.host, uri.port)
  #   http.use_ssl = true

  #   request = Net::HTTP::Get.new(uri)
  #   request['Authorization'] = "Bearer #{access_token}"

  #   response = http.request(request)
  #   JSON.parse(response.body)
  # end
  # def write_token_to_file(identifier, token_data)
  #   return unless identifier && token_data

  #   file_path = token_file_path(identifier)
  #   FileUtils.mkdir_p(File.dirname(file_path))

  #   File.write(file_path, JSON.pretty_generate(token_data))
  # end
  # def token_file_path(identifier)
  #   Rails.root.join('tmp', 'google_tokens', "token_#{identifier}.json")
  # end
end

Api::V2::CallbackController.prepend_mod_with('Api::V2::CallbackController')
