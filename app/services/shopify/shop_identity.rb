class Shopify::ShopIdentity
  QUERY = <<~GRAPHQL.freeze
    query ShopIdentity {
      shop {
        id
        myshopifyDomain
      }
    }
  GRAPHQL

  class ProviderError < StandardError; end

  def initialize(hook:)
    @hook = hook
  end

  def shop_id
    shop = fetch_shop
    raise ProviderError, 'Shopify Admin API returned a different shop' unless matching_shop?(shop)

    shop.fetch('id')
  rescue ProviderError
    raise
  rescue Shopify::ApiContext::ConfigurationError,
         ShopifyAPI::Errors::HttpResponseError, ShopifyAPI::Errors::MaxHttpRetriesExceededError,
         Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED,
         JSON::ParserError, KeyError, NoMethodError, TypeError => e
    raise ProviderError, "Shopify Admin API shop lookup failed (#{e.class.name})"
  end

  private

  attr_reader :hook

  def fetch_shop
    response = client.query(query: QUERY)
    body = response.body
    raise ProviderError, 'Shopify Admin API returned GraphQL errors' if body['errors'].present?

    body.dig('data', 'shop')
  end

  def client
    Shopify::ApiContext.setup!
    session = ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
    ShopifyAPI::Clients::Graphql::Admin.new(session: session, api_version: Shopify::ApiContext::API_VERSION)
  end

  def matching_shop?(shop)
    stored_domain = Shopify::ShopDomain.normalize(hook.reference_id)
    returned_domain = Shopify::ShopDomain.normalize(shop.fetch('myshopifyDomain'))
    stored_domain == returned_domain && shop.fetch('id').match?(%r{\Agid://shopify/Shop/\d+\z})
  end
end
