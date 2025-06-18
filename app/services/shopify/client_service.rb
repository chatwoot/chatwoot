# app/services/shopify_client_service.rb
class ShopifyClientService
  include Shopify::IntegrationHelper
  def initialize(shop_domain:, access_token:)
    @shop_domain = shop_domain
    @access_token = access_token
    setup_context
  end

  def client
    @client ||= ShopifyAPI::Clients::Rest::Admin.new(session: shopify_session)
  end

  private

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
