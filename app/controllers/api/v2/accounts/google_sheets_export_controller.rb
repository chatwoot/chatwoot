##
# Controller for Google OAuth authorization.
# Handles authorization URL generation only.
#
# Actions:
# - authorize: Returns the Google OAuth authorization URL.
# - status: Checks authorization status from external service.
##
require 'httparty'

class Api::V2::Accounts::GoogleSheetsExportController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization

  # Returns the Google OAuth authorization URL for the user to grant access.
  def authorize
    authorization_url = build_google_auth_url
    render json: { authorization_url: authorization_url }
  end

  def status
    # Send GET request to check authorization status
    api_endpoint = GlobalConfigService.load('EXTERNAL_TOKEN_API_URL', nil)
    # Rails.logger.info "Checking authorization status from external service: #{api_endpoint}"
    status_url = "#{api_endpoint}/#{Current.account.id}/status"
    # Rails.logger.info "Authorization status URL: #{status_url}"

    begin
      response = HTTParty.get(status_url)

      if response.success?
        authorized = response.parsed_response['authorized'] || false

        if authorized
          render json: { authorized: true, authorization_url: build_google_auth_url }, status: :ok
        else
          render json: {
            authorized: false,
            authorization_url: build_google_auth_url
          }, status: :ok
        end
      else
        render json: {
          authorized: false,
          authorization_url: build_google_auth_url,
          error: 'Failed to check status from external service'
        }, status: :bad_gateway
      end
    rescue StandardError => e
      render json: {
        error: 'Failed to connect to external service',
        message: e.message, api_endpoint: api_endpoint, status_url: status_url
      }, status: :service_unavailable
    end
  end

  private

  # Ensures the current user is an administrator for the account.
  def check_admin_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  # Constructs and returns the Google OAuth authorization URL with required scopes and redirect URI.
  def build_google_auth_url(state = nil)
    client_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    base_url = request.base_url.chomp('/')
    account_id = params[:account_id] || @account_id || Current.account&.id
    redirect_uri = "#{base_url}/api/v2/callback"

    # Encode state with account_id
    original_state = state if state.present?
    state_payload = { original_state: original_state, account_id: account_id }.to_json
    encoded_state = Base64.urlsafe_encode64(state_payload)

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
      prompt: 'consent',
      state: encoded_state
    }

    "https://accounts.google.com/o/oauth2/auth?#{auth_params.to_query}"
  end
end
