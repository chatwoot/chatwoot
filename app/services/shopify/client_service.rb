# app/services/shopify_client_service.rb
class Shopify::ClientService
  include Shopify::IntegrationHelper

  def initialize(account_id)
    fetch_hook(account_id)
    @shop_domain = @hook.reference_id
    @access_token = @hook.access_token
    setup_context
  end

  def fetch_hook(account_id)
    @hook = Integrations::Hook.find_by!(account: account_id, app_id: 'shopify')
  end

  def shopify_client
    @client ||= ShopifyAPI::Clients::Rest::Admin.new(session: shopify_session)
  end

  def setup_context
    return if client_id.blank? || client_secret.blank?

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
    ShopifyAPI::Auth::Session.new(shop: @shop_domain, access_token: @access_token)
  end
end
