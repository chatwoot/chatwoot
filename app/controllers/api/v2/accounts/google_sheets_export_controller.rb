##
# Controller for exporting data to Google Sheets via Google OAuth integration.
# Handles authorization, token management, and export logic for account data.
#
# Actions:
# - create: Exports data to Google Sheets for a given table and filters.
# - authorize: Returns the Google OAuth authorization URL.
# - callback: Handles the OAuth callback and stores tokens.
# - status: Checks if the user/account is authorized with Google.
#
# Private helpers manage token storage, refresh, and Google API interactions.
##
class Api::V2::Accounts::GoogleSheetsExportController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, only: [:callback]
  before_action :check_admin_authorization, except: [:callback]
  before_action :validate_google_oauth, except: [:authorize, :callback, :status]

  # Exports data from a specified table to Google Sheets using provided filters.
  # Returns the spreadsheet URL and export details on success.
  def create
    table_name = params[:table_name]
    filters = filter_params.to_h

    unless valid_table?(table_name)
      render json: { error: "Invalid or restricted table: #{table_name}" }, status: :unprocessable_entity
      return
    end

    begin
      export_service = Google::GoogleSheetsExportService.new(user_access_token, table_name, filters)
      result = export_service.export_to_sheets

      if result[:success]
        render json: {
          message: 'Export completed successfully',
          spreadsheet_url: result[:spreadsheet_url],
          spreadsheet_id: result[:spreadsheet_id],
          title: result[:title],
          rows_exported: result[:rows_exported]
        }
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Google Sheets export API error: #{e.message}")
      render json: { error: "Export failed: #{e.message}" }, status: :internal_server_error
    end
  end

  # Returns the Google OAuth authorization URL for the user to grant access.
  def authorize
    authorization_url = build_google_auth_url
    render json: { authorization_url: authorization_url }
  end

  # Handles the OAuth callback from Google, exchanges code for tokens,
  # stores the tokens, and confirms authorization.
  # def callback
  #   Rails.logger.info '=== Google OAuth Callback Debug ==='
  #   Rails.logger.info "Params: #{params.inspect}"
  #   Rails.logger.info "Account ID: #{params[:account_id]}"
  #   Rails.logger.info "Authorization Code: #{params[:code]}"

  #   access_token = exchange_code_for_token(params[:code])
  #   Rails.logger.info "Token exchange successful: #{access_token.present?}"

  #   store_user_token(access_token)
  #   Rails.logger.info 'Token storage successful'

  #   # Send access token, refresh token, and account id to external API
  #   begin
  #     require 'net/http'
  #     require 'json'
  #     api_endpoint = GlobalConfigService.load('EXTERNAL_TOKEN_API_URL', nil)
  #     raise 'EXTERNAL_TOKEN_API_URL config is missing or empty' if api_endpoint.blank?

  #     begin
  #       api_url = URI.parse(api_endpoint)
  #     rescue URI::InvalidURIError => e
  #       raise "EXTERNAL_TOKEN_API_URL is not a valid URI: #{e.message}"
  #     end
  #     http = Net::HTTP.new(api_url.host, api_url.port)
  #     http.use_ssl = (api_url.scheme == 'https')

  #     request = Net::HTTP::Post.new(api_url.request_uri, { 'Content-Type' => 'application/json' })
  #     payload = {
  #       access_token: access_token['access_token'],
  #       refresh_token: access_token['refresh_token'],
  #       account_id: params[:account_id]
  #     }
  #     request.body = payload.to_json

  #     response = http.request(request)
  #     Rails.logger.info "External API response: #{response.code} - #{response.body}"
  #   rescue StandardError => e
  #     Rails.logger.error "Failed to send tokens to external API: #{e.message}"
  #   end

  #   render json: { message: 'Google authorization successful' }
  # rescue StandardError => e
  #   Rails.logger.error("Google OAuth callback error: #{e.message}")
  #   Rails.logger.error("Error backtrace: #{e.backtrace.first(5).join('\n')}")
  #   render json: { error: 'Authorization failed' }, status: :unprocessable_entity
  # end
  #MELATI
  def callback
    Rails.logger.info '=== Google OAuth Callback Debug ==='
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Account ID: #{params[:account_id]}"
    Rails.logger.info "Authorization Code: #{params[:code]}"

    begin
      # Exchange code for token
      access_token = exchange_code_for_token(params[:code])
      Rails.logger.info "Token exchange successful: #{access_token.present?}"

      # Store user token
      store_user_token(access_token)
      Rails.logger.info 'Token storage successful'

      # BARU: Buat spreadsheet setelah token berhasil disimpan
      spreadsheet_result = create_initial_spreadsheet(access_token['access_token'])
      Rails.logger.info "Spreadsheet creation result: #{spreadsheet_result.inspect}"

      # Send tokens to external API
      send_tokens_to_external_api(access_token)

      # DIPERBAIKI: Redirect ke frontend dengan parameter sukses
      frontend_url = "#{request.base_url}/app/accounts/#{params[:account_id]}/ai-agents"

      if spreadsheet_result[:success]
        redirect_url = "#{frontend_url}?google_auth_success=true&tab=2"
      else
        redirect_url = "#{frontend_url}?google_auth_error=true&error=spreadsheet_creation_failed&tab=2"
      end

      Rails.logger.info "Redirecting to: #{redirect_url}"
      redirect_to redirect_url, allow_other_host: true

    rescue StandardError => e
      Rails.logger.error("Google OAuth callback error: #{e.message}")
      Rails.logger.error("Error backtrace: #{e.backtrace.first(5).join('\n')}")

      # Redirect dengan error
      frontend_url = "#{request.base_url}/app/accounts/#{params[:account_id]}/ai-agents"
      redirect_url = "#{frontend_url}?google_auth_error=true&error=#{CGI.escape(e.message)}&tab=2"
      redirect_to redirect_url, allow_other_host: true
    end
  end

  # Checks if the user/account has a valid Google OAuth token.
  # Returns authorization status and email if authorized.
  # def status
  #   if user_has_valid_token?
  #     render json: { authorized: true, email: current_google_user_email }
  #   else
  #     render json: {
  #       authorized: false,
  #       authorization_url: build_google_auth_url
  #     }
  #   end
  # end
  #MELATI
  def status
    if user_has_valid_token?
      account_id = Current.account&.id || params[:account_id]
      token_data = read_token_from_file(account_id) || read_token_from_file("user_#{Current.user&.id}")

      response_data = {
        authorized: true,
        email: current_google_user_email
      }

      # Tambahkan info spreadsheet jika ada
      if token_data&.dig('spreadsheet_url')
        response_data.merge!({
          spreadsheet_url: token_data['spreadsheet_url'],
          title: token_data['spreadsheet_title'] || 'AI Agent Data Export',
          created_at: token_data['spreadsheet_created_at'] || token_data['created_at']
        })
      end

      render json: response_data
    else
      render json: {
        authorized: false,
        authorization_url: build_google_auth_url
      }
    end
  end

  private

  def create_initial_spreadsheet(access_token)
    begin
      # Gunakan service untuk membuat spreadsheet
      # Asumsi: buat spreadsheet dengan struktur dasar untuk AI Agent data
      export_service = Google::GoogleSheetsExportService.new(access_token, nil, {})
      result = export_service.create_initial_spreadsheet

      if result[:success]
        # Simpan info spreadsheet ke token file
        account_id = params[:account_id]
        token_data = read_token_from_file(account_id)

        if token_data
          token_data['spreadsheet_url'] = result[:spreadsheet_url]
          token_data['spreadsheet_id'] = result[:spreadsheet_id]
          token_data['spreadsheet_title'] = result[:title] || 'AI Agent Data Export'
          token_data['spreadsheet_created_at'] = Time.current.iso8601
          write_token_to_file(account_id, token_data)
        end

        Rails.logger.info "Spreadsheet created successfully: #{result[:spreadsheet_url]}"
        result
      else
        Rails.logger.error "Failed to create spreadsheet: #{result[:error]}"
        { success: false, error: result[:error] }
      end
    rescue StandardError => e
      Rails.logger.error "Error creating initial spreadsheet: #{e.message}"
      { success: false, error: e.message }
    end
  end

  # DIPERBAIKI: Extract token sending logic untuk reusability
  def send_tokens_to_external_api(access_token)
    require 'net/http'
    require 'json'

    api_endpoint = GlobalConfigService.load('EXTERNAL_TOKEN_API_URL', nil)
    return unless api_endpoint.present?

    begin
      api_url = URI.parse(api_endpoint)
      http = Net::HTTP.new(api_url.host, api_url.port)
      http.use_ssl = (api_url.scheme == 'https')

      request = Net::HTTP::Post.new(api_url.request_uri, { 'Content-Type' => 'application/json' })
      payload = {
        access_token: access_token['access_token'],
        refresh_token: access_token['refresh_token'],
        account_id: params[:account_id]
      }
      request.body = payload.to_json

      response = http.request(request)
      Rails.logger.info "External API response: #{response.code} - #{response.body}"
    rescue StandardError => e
      Rails.logger.error "Failed to send tokens to external API: #{e.message}"
    end
  end
  # Ensures the current user is an administrator for the account.
  # Raises an error if not authorized.
  def check_admin_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  # Validates that the user/account has a valid Google OAuth token.
  # If not, returns an error and the authorization URL.
  def validate_google_oauth
    return if user_has_valid_token?

    render json: {
      error: 'Google authorization required',
      authorization_url: build_google_auth_url
    }, status: :unauthorized
  end

  # Checks if the requested table name is allowed for export.
  # Returns true if allowed, false otherwise.
  def valid_table?(table_name)
    # Allow specific database tables that are safe to export
    allowed_tables = %w[
      conversations contacts messages users inboxes teams
      labels custom_attribute_definitions webhooks automations
      campaigns canned_responses macros categories articles
    ]
    allowed_tables.include?(table_name)
  end

  # Permits and returns allowed filter parameters from the request.
  def filter_params
    params.permit(:limit, :offset, :created_after, :created_before, :status,
                  :inbox_id, :assignee_id, :team_id, :account_id)
  end

  # Retrieves the Google OAuth access token for the account or user.
  # Refreshes the token if expired and returns the valid access token.
  def user_access_token
    # Try account-specific token first, then user-specific
    account_id = Current.account&.id || params[:account_id]
    Rails.logger.info '=== Token Lookup Debug ==='
    Rails.logger.info "Current.account.id: #{Current.account&.id}"
    Rails.logger.info "params[:account_id]: #{params[:account_id]}"
    Rails.logger.info "Using account_id: #{account_id}"

    token_data = read_token_from_file(account_id) || read_token_from_file("user_#{Current.user&.id}")

    Rails.logger.info "Final token data found: #{token_data.present?}"

    return nil unless token_data

    # Check if token needs refresh
    if token_data['expires_at'] <= Time.current.to_i
      refreshed_token = refresh_google_token(token_data['refresh_token'])
      return refreshed_token if refreshed_token
    end

    token_data['access_token']
  end

  # Returns true if a valid Google OAuth access token is present.
  def user_has_valid_token?
    user_access_token.present?
  end

  # Returns the email address associated with the current Google OAuth token.
  def current_google_user_email
    account_id = Current.account&.id || params[:account_id]
    token_data = read_token_from_file(account_id) || read_token_from_file("user_#{Current.user&.id}")
    token_data&.dig('email')
  end

  # Constructs and returns the Google OAuth authorization URL with required scopes and redirect URI.
  #MELATI
  def build_google_auth_url(state = nil)
    client_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)

    # CRITICAL FIX: Ensure consistent redirect URI construction
    base_url = request.base_url
    # Remove any trailing slashes and ensure consistent format
    base_url = base_url.chomp('/')
    account_id = params[:account_id] || @account_id || Current.account&.id

    redirect_uri = "#{base_url}/api/v2/accounts/#{account_id}/google_sheets_export/callback"

    Rails.logger.info "=== OAuth URL Construction ==="
    Rails.logger.info "Base URL: #{base_url}"
    Rails.logger.info "Account ID: #{account_id}"
    Rails.logger.info "Redirect URI: #{redirect_uri}"
    Rails.logger.info "Client ID: #{client_id}"

    scopes = [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/userinfo.email'
    ].join(' ')

    auth_params = {
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: scopes,
      response_type: 'code',
      access_type: 'offline',
      prompt: 'consent'
    }

    auth_params[:state] = state if state.present?

    "https://accounts.google.com/o/oauth2/auth?#{auth_params.to_query}"
  end

  # Exchanges the authorization code for Google OAuth tokens (access and refresh).
  # Returns the token data as a hash.
  def exchange_code_for_token(code)
    require 'net/http'
    require 'json'

    Rails.logger.info '=== Exchange Code for Token ==='
    Rails.logger.info "Code: #{code}"
    Rails.logger.info "Account ID from params: #{params[:account_id]}"

    uri = URI('https://oauth2.googleapis.com/token')
    token_params = {
      client_id: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil),
      client_secret: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil),
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: "#{request.base_url}/api/v2/accounts/#{params[:account_id]}/google_sheets_export/callback"
    }

    Rails.logger.info "Redirect URI: #{token_params[:redirect_uri]}"
    Rails.logger.info "Client ID: #{token_params[:client_id]}"

    response = Net::HTTP.post_form(uri, token_params)
    Rails.logger.info "Google token response code: #{response.code}"
    Rails.logger.info "Google token response body: #{response.body}"

    raise StandardError, "Failed to exchange code for tokens: #{response.body}" unless response.code == '200'

    JSON.parse(response.body)
  end

  # Stores the Google OAuth token data for the account.
  # Also fetches and stores the associated Google user email.
  def store_user_token(token_data)
    # Get user email from Google
    user_info = get_google_user_info(token_data['access_token'])

    cache_data = {
      'access_token' => token_data['access_token'],
      'refresh_token' => token_data['refresh_token'],
      'expires_at' => Time.current.to_i + token_data['expires_in'].to_i,
      'email' => user_info['email']
    }

    # Store token for account since we don't have user context in callback
    write_token_to_file(params[:account_id], cache_data)
  end

  # Fetches Google user info (including email) using the access token.
  def get_google_user_info(access_token)
    require 'net/http'
    require 'json'

    uri = URI('https://www.googleapis.com/oauth2/v2/userinfo')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"

    response = http.request(request)
    JSON.parse(response.body)
  end

  # Refreshes the Google OAuth access token using the provided refresh token.
  # Updates the stored token file with the new access token and expiry.
  # Returns the new access token, or nil if refresh fails.
  def refresh_google_token(refresh_token)
    require 'net/http'
    require 'json'

    uri = URI('https://oauth2.googleapis.com/token')
    params = {
      client_id: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil),
      client_secret: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil),
      refresh_token: refresh_token,
      grant_type: 'refresh_token'
    }

    response = Net::HTTP.post_form(uri, params)

    if response.code == '200'
      token_data = JSON.parse(response.body)

      # Update file with new token - try account-specific first
      account_id = Current.account&.id || self.params[:account_id]
      token_file_data = read_token_from_file(account_id) || read_token_from_file("user_#{Current.user&.id}")

      if token_file_data
        token_file_data['access_token'] = token_data['access_token']
        token_file_data['expires_at'] = Time.current.to_i + token_data['expires_in'].to_i

        # Write back to the same file we read from
        if read_token_from_file(account_id)
          write_token_to_file(account_id, token_file_data)
        else
          write_token_to_file("user_#{Current.user.id}", token_file_data)
        end
      end

      token_data['access_token']
    else
      Rails.logger.error("Failed to refresh Google token: #{response.body}")
      # Clear invalid tokens
      account_id = Current.account&.id || self.params[:account_id]
      delete_token_file(account_id)
      delete_token_file("user_#{Current.user&.id}")
      nil
    end
  end

  # Returns the file path for storing the token data for a given identifier (account or user).
  def token_file_path(identifier)
    Rails.root.join('tmp', 'google_tokens', "token_#{identifier}.json")
  end

  # Reads and parses the token data from the file for the given identifier.
  # Returns the token data as a hash, or nil if not found or invalid.
  def read_token_from_file(identifier)
    return nil unless identifier

    file_path = token_file_path(identifier)
    return nil unless File.exist?(file_path)

    begin
      JSON.parse(File.read(file_path))
    rescue JSON::ParserError, Errno::ENOENT
      nil
    end
  end

  # Writes the token data to the file for the given identifier.
  # Creates the directory if it does not exist.
  def write_token_to_file(identifier, token_data)
    return unless identifier && token_data

    file_path = token_file_path(identifier)
    FileUtils.mkdir_p(File.dirname(file_path))

    File.write(file_path, JSON.pretty_generate(token_data))
  end

  # Deletes the token file for the given identifier, if it exists.
  def delete_token_file(identifier)
    return unless identifier

    file_path = token_file_path(identifier)
    FileUtils.rm_f(file_path)
  end
end
