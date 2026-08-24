class Captain::ToolCatalog::ShopifyGraphqlClient < Captain::ToolCatalog::HttpClient
  API_VERSION = '2026-07'.freeze
  ENDPOINT_STRATEGY = 'shopify_admin_graphql'.freeze
  DYNAMIC_ORIGIN = Captain::ToolCatalog::ProviderPackValidator::SHOPIFY_DYNAMIC_ORIGIN

  private

  def graphql_request(request, arguments)
    validate_endpoint_strategy!(request)

    [endpoint_url, JSON.generate(query: operation.fetch('definition'), variables: arguments)]
  end

  def validate_endpoint_strategy!(request)
    return if request['endpoint_strategy'] == ENDPOINT_STRATEGY

    raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_tool_snapshot')
  end

  def validate_origin!(url)
    allowed = custom_tool.definition.fetch('allowed_origins').include?(DYNAMIC_ORIGIN)
    return if allowed && url == endpoint_url

    raise Captain::ToolCatalog::ExecutionError.new('validation', 'origin_not_allowed')
  end

  def endpoint_url
    shop_domain = Shopify::ShopDomain.normalize(custom_tool.integration_hook&.reference_id)
    raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_shopify_domain') unless Shopify::ShopDomain.valid?(shop_domain)

    "https://#{shop_domain}/admin/api/#{API_VERSION}/graphql.json"
  end
end
