class Shopify::StorefrontWidget
  class ProviderError < StandardError; end
  class ReauthorizationRequired < ProviderError; end

  NAMESPACE = 'chatwoot'.freeze
  KEY = 'website_token'.freeze
  EMBED_HANDLE = 'chatwoot-chat'.freeze

  INSTALLATION_QUERY = <<~GRAPHQL.freeze
    query StorefrontWidget($namespace: String!, $key: String!) {
      currentAppInstallation {
        id
        metafield(namespace: $namespace, key: $key) { value }
      }
    }
  GRAPHQL

  SET_METAFIELD_MUTATION = <<~GRAPHQL.freeze
    mutation SetStorefrontWidget($metafields: [MetafieldsSetInput!]!) {
      metafieldsSet(metafields: $metafields) {
        metafields { id }
        userErrors { code }
      }
    }
  GRAPHQL

  DELETE_METAFIELD_MUTATION = <<~GRAPHQL.freeze
    mutation DeleteStorefrontWidget($metafields: [MetafieldIdentifierInput!]!) {
      metafieldsDelete(metafields: $metafields) {
        deletedMetafields { key }
        userErrors { field message }
      }
    }
  GRAPHQL

  def initialize(hook:)
    @hook = hook
  end

  def website_token
    installation.dig('metafield', 'value')
  end

  def save!(website_token:)
    metafield = {
      ownerId: installation.fetch('id'), namespace: NAMESPACE, key: KEY,
      type: 'single_line_text_field', value: website_token
    }
    result = query(SET_METAFIELD_MUTATION, metafields: [metafield])['metafieldsSet']
    return if result && result['userErrors'].blank? && result['metafields'].present?

    raise ProviderError, 'Shopify did not save the storefront widget'
  end

  def clear!
    app_installation = installation
    return if app_installation['metafield'].nil?

    identifier = { ownerId: app_installation.fetch('id'), namespace: NAMESPACE, key: KEY }
    result = query(DELETE_METAFIELD_MUTATION, metafields: [identifier])['metafieldsDelete']
    return if result && result['userErrors'] == [] && result['deletedMetafields']&.size == 1

    raise ProviderError, 'Shopify did not remove the storefront widget'
  end

  def theme_editor_url
    client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
    raise ProviderError, 'Shopify app client ID is unavailable' if client_id.blank?

    query = URI.encode_www_form(context: 'apps', activateAppId: "#{client_id}/#{EMBED_HANDLE}")
    "https://#{@hook.reference_id}/admin/themes/current/editor?#{query}"
  end

  private

  def installation
    result = query(INSTALLATION_QUERY, namespace: NAMESPACE, key: KEY)['currentAppInstallation']
    return result if result&.dig('id').present?

    raise ProviderError, 'Shopify app installation is unavailable'
  end

  def query(document, variables)
    response = client.query(query: document, variables: variables).body
    return response['data'] if response['errors'].blank? && response['data'].present?

    raise ProviderError, 'Shopify storefront widget request failed'
  rescue ShopifyAPI::Errors::HttpResponseError => e
    raise ReauthorizationRequired, 'Shopify rejected the saved storefront credentials' if e.code == 401

    raise ProviderError, "Shopify storefront widget request failed (HTTP #{e.code})"
  rescue Shopify::ApiContext::ConfigurationError,
         ShopifyAPI::Errors::MaxHttpRetriesExceededError, Net::OpenTimeout, Net::ReadTimeout,
         SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
    raise ProviderError, "Shopify storefront widget request failed (#{e.class.name})"
  end

  def client
    @client ||= begin
      Shopify::ApiContext.setup!
      session = ShopifyAPI::Auth::Session.new(shop: @hook.reference_id, access_token: @hook.access_token)
      ShopifyAPI::Clients::Graphql::Admin.new(session: session, api_version: Shopify::ApiContext::API_VERSION)
    end
  end
end
