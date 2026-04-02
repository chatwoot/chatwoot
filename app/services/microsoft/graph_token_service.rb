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
    uri = URI(TOKEN_URL)

    response = Net::HTTP.post_form(uri, {
      client_id: GlobalConfigService.load('AZURE_APP_ID', ''),
      client_secret: GlobalConfigService.load('AZURE_APP_SECRET', ''),
      refresh_token: provider_config['refresh_token'],
      grant_type: 'refresh_token',
      scope: GRAPH_SCOPE
    })

    if response.code.to_i == 200
      token_data = JSON.parse(response.body)
      token_data['access_token']
    else
      error_data = JSON.parse(response.body) rescue { 'error_description' => response.body }
      Rails.logger.error("Microsoft Graph token refresh failed: #{error_data['error_description']}")
      raise StandardError, "Failed to get Graph API token: #{error_data['error_description']}"
    end
  end

  def provider_config
    @provider_config ||= channel.provider_config.with_indifferent_access
  end
end
