shopify_client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
shopify_client_secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
required_scopes = %w[read_customers read_orders read_fulfillments].freeze

unless shopify_client_id.blank? || shopify_client_secret.blank?
  ShopifyAPI::Context.setup(
    api_key: shopify_client_id,
    api_secret_key: shopify_client_secret,
    api_version: '2025-01'.freeze,
    scope: required_scopes.join(',')
  )
end
