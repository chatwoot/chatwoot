class Captain::ToolCatalog::UpdateWorkflow < Captain::ToolCatalog::BaseWorkflow
  def perform(provider_key:, templates:)
    selection = resolve_selection(provider_key, templates)
    create_installation!(
      workflow_kind: 'update',
      provider_key: provider_key,
      selected_templates: selection.serialized
    )
    execute(selection)
  end

  def resume(installation)
    resume_installation!(installation)
    return installation if installation.completed?

    execute(resolve_selection(installation.provider_key, installation.selected_templates))
  end

  private

  def execute(selection)
    track_failure do
      installed_by_key = installed_tools(selection).index_by(&:template_key)
      ensure_all_installed!(selection, installed_by_key)

      requirement = connection_requirement(selection.pack.dig('provider', 'key'), selection.required_scopes)
      return await_connection!(requirement) unless requirement.satisfied?

      update_snapshots!(selection, requirement.hook)
    end
  end

  def update_snapshots!(selection, integration_hook)
    installation.update!(status: 'validating', integration_hook: integration_hook)

    account.with_lock do
      installed_by_key = installed_tools(selection).index_by(&:template_key)
      ensure_all_installed!(selection, installed_by_key)
      installation.update!(status: 'installing')

      selection.items.each do |entry|
        installed_by_key.fetch(entry.dig(:template, 'key')).update!(
          Captain::ToolCatalog::SnapshotBuilder.new(pack: selection.pack, entry: entry, integration_hook: integration_hook).attributes
        )
      end

      complete!(selection.items.map { |entry| installed_by_key.fetch(entry.dig(:template, 'key')) }, integration_hook: integration_hook)
    end
  end

  def installed_tools(selection)
    keys = selection.items.map { |entry| entry.dig(:template, 'key') }
    account.captain_custom_tools.catalog.where(provider_key: selection.pack.dig('provider', 'key'), template_key: keys).to_a
  end

  def ensure_all_installed!(selection, installed_by_key)
    expected_keys = selection.items.map { |entry| entry.dig(:template, 'key') }
    return if expected_keys.all? { |key| installed_by_key.key?(key) }

    raise Captain::ToolCatalog::WorkflowError, 'installed_tool_not_found'
  end
end
