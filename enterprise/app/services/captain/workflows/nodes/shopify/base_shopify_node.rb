class Captain::Workflows::Nodes::Shopify::BaseShopifyNode < Captain::Workflows::Nodes::BaseNode
  include ::Shopify::IntegrationHelper

  private

  def hook
    @hook ||= Integrations::Hook.find_by!(account: account, app_id: 'shopify')
  end

  def setup_shopify_context
    ShopifyAPI::Context.setup(
      api_key: client_id,
      api_secret_key: client_secret,
      api_version: '2025-01'.freeze,
      scope: REQUIRED_SCOPES.join(','),
      is_embedded: true,
      is_private: false
    )
  end

  def shopify_session
    ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
  end

  def shopify_client
    @shopify_client ||= begin
      setup_shopify_context
      ShopifyAPI::Clients::Rest::Admin.new(session: shopify_session)
    end
  end
end
