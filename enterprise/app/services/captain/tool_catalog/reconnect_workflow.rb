class Captain::ToolCatalog::ReconnectWorkflow < Captain::ToolCatalog::BaseWorkflow
  def perform(provider_key:)
    registry.find(provider_key)
    tools = installed_tools(provider_key)
    raise Captain::ToolCatalog::WorkflowError, 'installed_tools_required' if tools.empty?

    create_installation!(
      workflow_kind: 'reconnect',
      provider_key: provider_key,
      selected_templates: serialize_tools(tools)
    )
    execute(tools)
  end

  def resume(installation)
    resume_installation!(installation)
    return installation if installation.completed?

    tools = account.captain_custom_tools.catalog.where(
      provider_key: installation.provider_key,
      template_key: installation.selected_templates.pluck('template_key')
    ).to_a
    raise Captain::ToolCatalog::WorkflowError, 'installed_tool_not_found' if tools.length != installation.selected_templates.length

    execute(tools)
  end

  private

  def execute(tools)
    track_failure do
      require_encryption!
      requirement = connection_requirement(installation.provider_key, required_scopes(tools))
      return await_connection!(requirement) unless requirement.satisfied?

      relink_tools!(tools, requirement.hook)
    end
  end

  def relink_tools!(tools, integration_hook)
    installation.update!(status: 'validating', integration_hook: integration_hook)

    account.with_lock do
      tools.each { |tool| tool.update!(integration_hook: integration_hook) }
      installation.update!(status: 'installing')
      complete!(tools, integration_hook: integration_hook)
    end
  end

  def installed_tools(provider_key)
    account.captain_custom_tools.catalog.where(provider_key: provider_key).order(:id).to_a
  end

  def serialize_tools(tools)
    tools.map do |tool|
      {
        'template_key' => tool.template_key,
        'template_version' => tool.template_version,
        'configuration' => tool.configuration
      }
    end
  end

  def required_scopes(tools)
    tools.flat_map do |tool|
      tool.definition.fetch('operations').flat_map { |operation| operation.fetch('scopes') }
    end.uniq.sort
  end
end
