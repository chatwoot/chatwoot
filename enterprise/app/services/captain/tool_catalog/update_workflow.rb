class Captain::ToolCatalog::UpdateWorkflow < Captain::ToolCatalog::BaseWorkflow
  def perform(provider_key:, templates:, credential: nil)
    selection = resolve_selection(provider_key, templates, allow_empty: true)
    create_installation!(
      workflow_kind: 'update',
      provider_key: provider_key,
      selected_templates: selection.serialized
    )
    execute(selection, credential: credential)
  end

  def resume(installation)
    resume_installation!(installation)
    return installation if installation.completed?

    execute(resolve_selection(installation.provider_key, installation.selected_templates, allow_empty: true))
  end

  private

  def execute(selection, credential: nil)
    track_failure do
      installed_by_key = installed_tools(selection).index_by(&:template_key)
      connection_entries = connection_entries(selection, installed_by_key)
      provider_key = selection.pack.dig('provider', 'key')
      required_scopes = selection.required_scopes(connection_entries)
      connect_provider!(provider_key: provider_key, credential: credential, required_scopes: required_scopes)
      requirement = connection_requirement(provider_key, required_scopes)
      return await_connection!(requirement) if connection_entries.any? && !requirement.satisfied?

      sync_tools!(selection, requirement.hook)
    end
  end

  def sync_tools!(selection, integration_hook)
    installation.update!(status: 'validating', integration_hook: integration_hook)

    account.with_lock do
      installed_by_key = installed_tools(selection).index_by(&:template_key)
      removed_tools, missing_entries = tool_changes(selection, installed_by_key)
      validate_capacity_without_lock!(removed_tools.length, missing_entries.length)
      installation.update!(status: 'installing')

      removed_tools.each(&:destroy!)
      sync_selected_tools!(selection, installed_by_key, integration_hook)

      complete!(tools_in_selection_order(selection, installed_by_key), integration_hook: integration_hook)
    end
  end

  def installed_tools(selection)
    account.captain_custom_tools.catalog.where(provider_key: selection.pack.dig('provider', 'key')).to_a
  end

  def connection_entries(selection, installed_by_key)
    selection.items.select do |entry|
      tool = installed_by_key[entry.dig(:template, 'key')]
      tool.blank? || tool.template_version != entry.dig(:template, 'version')
    end
  end

  def tool_changes(selection, installed_by_key)
    selected_keys = selection.items.map { |entry| entry.dig(:template, 'key') }
    removed_tools = installed_by_key.values.reject { |tool| selected_keys.include?(tool.template_key) }
    missing_entries = selection.items.reject { |entry| installed_by_key.key?(entry.dig(:template, 'key')) }
    [removed_tools, missing_entries]
  end

  def sync_selected_tools!(selection, installed_by_key, integration_hook)
    selection.items.each do |entry|
      template_key = entry.dig(:template, 'key')
      tool = installed_by_key[template_key]
      attributes = Captain::ToolCatalog::SnapshotBuilder.new(
        pack: selection.pack,
        entry: entry,
        integration_hook: integration_hook || tool&.integration_hook
      ).attributes

      if tool
        tool.update!(attributes)
      else
        installed_by_key[template_key] = account.captain_custom_tools.create!(attributes)
      end
    end
  end

  def tools_in_selection_order(selection, tools_by_key)
    selection.items.map { |entry| tools_by_key.fetch(entry.dig(:template, 'key')) }
  end

  def validate_capacity_without_lock!(removed_count, missing_count)
    limit = Captain::CustomTool.limit_for(account)
    return if account.captain_custom_tools.count - removed_count + missing_count <= limit

    raise Captain::ToolCatalog::WorkflowError, 'tool_capacity_exceeded'
  end
end
