class Captain::ToolCatalog::ShopifyBindingValidator
  BINDING_FIELDS = {
    'shopify_contact_query' => %w[source],
    'shopify_order_query' => %w[path source]
  }.freeze

  def validate!(binding, provider_key:, input_schema:)
    source = binding.fetch('source')
    raise Captain::ToolCatalog::ProviderPackError, "#{source} bindings are only available to Shopify Provider Packs" unless provider_key == 'shopify'
    raise Captain::ToolCatalog::ProviderPackError, "Unexpected fields for #{source} binding" unless binding.keys.sort == BINDING_FIELDS.fetch(source)
    return if source == 'shopify_contact_query'

    path = binding.fetch('path')
    return if input_schema.fetch('properties', {}).key?(path.split('.').first)

    raise Captain::ToolCatalog::ProviderPackError, "Unknown #{source} binding: #{path}"
  end
end
