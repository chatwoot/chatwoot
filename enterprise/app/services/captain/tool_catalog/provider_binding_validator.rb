class Captain::ToolCatalog::ProviderBindingValidator
  VALIDATORS = {
    'shopify_' => Captain::ToolCatalog::ShopifyBindingValidator,
    'linear_' => Captain::ToolCatalog::LinearBindingValidator,
    'slack_' => Captain::ToolCatalog::SlackBindingValidator
  }.freeze

  def validate!(binding, provider_key:, step_index:, input_schema:)
    validator = VALIDATORS.find { |prefix, _validator| binding.fetch('source').start_with?(prefix) }&.last
    return false if validator.blank?

    arguments = { provider_key: provider_key, input_schema: input_schema }
    arguments[:step_index] = step_index if validator == Captain::ToolCatalog::LinearBindingValidator
    validator.new.validate!(binding, **arguments)
    true
  end
end
