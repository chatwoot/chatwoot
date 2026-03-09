# Refer: https://learn.microsoft.com/en-us/entra/identity-platform/configurable-token-lifetimes
class Google::RefreshOauthTokenService < BaseRefreshOauthTokenService
  private

  # Builds the OAuth strategy for Microsoft Graph
  def build_oauth_strategy
    app_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    app_secret = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil)

    OmniAuth::Strategies::GoogleOauth2.new(nil, app_id, app_secret)
  end
end
