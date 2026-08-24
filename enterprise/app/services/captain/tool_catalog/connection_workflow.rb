class Captain::ToolCatalog::ConnectionWorkflow < Captain::ToolCatalog::BaseWorkflow
  def perform(provider_key:, templates:)
    selection = resolve_selection(provider_key, templates, validate_configuration: false)
    require_encryption!
    create_installation!(
      workflow_kind: 'connect',
      provider_key: provider_key,
      selected_templates: selection.serialized
    )
    requirement = connection_requirement(provider_key, selection.required_scopes)
    await_connection!(requirement)
  end

  def resume(installation)
    installation
  end
end
