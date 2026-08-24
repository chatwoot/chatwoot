class Captain::ToolCatalog::LinearBindingValidator
  BINDING_FIELDS = {
    'linear_conversation_url' => %w[source],
    'linear_linked_issue_id' => %w[path source step]
  }.freeze

  def validate!(binding, provider_key:, step_index:, input_schema:)
    source = binding.fetch('source')
    raise Captain::ToolCatalog::ProviderPackError, "#{source} bindings are only available to Linear Provider Packs" unless provider_key == 'linear'

    raise Captain::ToolCatalog::ProviderPackError, "Unexpected fields for #{source} binding" unless binding.keys.sort == BINDING_FIELDS.fetch(source)
    return if source == 'linear_conversation_url'

    validate_linked_issue_binding!(binding, step_index, input_schema)
  end

  private

  def validate_linked_issue_binding!(binding, step_index, input_schema)
    if binding.fetch('step') >= step_index
      raise Captain::ToolCatalog::ProviderPackError,
            "Recipe step #{step_index} cannot read step #{binding.fetch('step')}"
    end
    return if input_schema.fetch('properties', {}).key?(binding.fetch('path').split('.').first)

    raise Captain::ToolCatalog::ProviderPackError, "Unknown linear_linked_issue_id binding: #{binding.fetch('path')}"
  end
end
