class Captain::ToolCatalog::SlackBindingValidator
  SOURCES = %w[slack_reference_channel slack_reference_timestamp].freeze

  def validate!(binding, provider_key:, input_schema:)
    source = binding.fetch('source')
    raise Captain::ToolCatalog::ProviderPackError, "#{source} bindings are only available to Slack Provider Packs" unless provider_key == 'slack'
    raise Captain::ToolCatalog::ProviderPackError, "Unexpected fields for #{source} binding" unless binding.keys.sort == %w[path source]

    path = binding.fetch('path')
    return if input_schema.fetch('properties', {}).key?(path.split('.').first)

    raise Captain::ToolCatalog::ProviderPackError, "Unknown #{source} binding: #{path}"
  end
end
