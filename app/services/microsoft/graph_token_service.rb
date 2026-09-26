# Service to get an access token specifically for Microsoft Graph API
# The regular OAuth token is for outlook.office.com (IMAP), but Graph API needs
# a token with audience https://graph.microsoft.com
class Microsoft::GraphTokenService
  pattr_initialize [:channel!]

  GRAPH_SCOPE = 'https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/Mail.ReadWrite offline_access'.freeze
  TOKEN_URL = 'https://login.microsoftonline.com/common/oauth2/v2.0/token'.freeze

  def access_token
    # Use the refresh token to get a new access token specifically for Graph API
    refresh_for_graph_api
  end

  private

  def refresh_for_graph_api
    response = Net::HTTP.post_form(URI(TOKEN_URL), token_params)

    raise_token_error(response) unless response.code.to_i == 200

    JSON.parse(response.body)['access_token']
  end

  def token_params
    {
      client_id: GlobalConfigService.load('AZURE_APP_ID', ''),
      client_secret: GlobalConfigService.load('AZURE_APP_SECRET', ''),
      refresh_token: provider_config['refresh_token'],
      grant_type: 'refresh_token',
      scope: GRAPH_SCOPE
    }
  end

  def raise_token_error(response)
    error_data = begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      { 'error_description' => response.body }
    end
    Rails.logger.error("Microsoft Graph token refresh failed: #{error_data['error_description']}")
    raise StandardError, "Failed to get Graph API token: #{error_data['error_description']}"
  end

  def provider_config
    @provider_config ||= channel.provider_config.with_indifferent_access
  end
end
