# Refer: https://learn.microsoft.com/en-us/entra/identity-platform/configurable-token-lifetimes
class Microsoft::RefreshOauthTokenService < BaseRefreshOauthTokenService
  private

  # Builds the OAuth strategy for Microsoft Graph
  def build_oauth_strategy
    ::MicrosoftGraphAuth.new(nil, GlobalConfigService.load('AZURE_APP_ID', ''), GlobalConfigService.load('AZURE_APP_SECRET', ''))
  end
end
