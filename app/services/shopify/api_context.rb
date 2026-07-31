class Shopify::ApiContext
  API_VERSION = ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION
  class ConfigurationError < StandardError; end

  def self.setup!
    api_key = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil).to_s
    api_secret_key = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil).to_s
    raise ConfigurationError, 'Shopify API credentials are unavailable' if api_key.blank? || api_secret_key.blank?

    ShopifyAPI::Context.setup(
      api_key: api_key,
      api_secret_key: api_secret_key,
      api_version: API_VERSION,
      scope: Shopify::IntegrationHelper::REQUIRED_SCOPES.join(','),
      is_embedded: true,
      is_private: false
    )
  end
end
