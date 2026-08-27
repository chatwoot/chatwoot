class Captain::ToolCatalog::InstallationWorkflow < Captain::ToolCatalog::BaseWorkflow
  def perform(provider_key:, templates:, credential: nil)
    selection = resolve_selection(provider_key, templates)
    create_installation!(
      workflow_kind: 'install',
      provider_key: provider_key,
      selected_templates: selection.serialized
    )
    execute(selection, credential: credential)
  end

  def resume(installation)
    resume_installation!(installation)
    return installation if installation.completed?

    selection = resolve_selection(installation.provider_key, installation.selected_templates)
    execute(selection)
  end

  private

  def execute(selection, credential: nil)
    track_failure do
      existing_by_key = installed_tools(selection).index_by(&:template_key)
      missing_entries = selection.items.reject { |entry| existing_by_key.key?(entry.dig(:template, 'key')) }
      validate_capacity!(missing_entries.length)
      return complete!(tools_in_selection_order(selection, existing_by_key), integration_hook: common_hook(existing_by_key)) if missing_entries.empty?

      requirement = prepare_connection(selection, missing_entries, credential)
      return await_connection!(requirement) unless requirement.satisfied?

      install_missing_tools!(selection, requirement.hook)
    end
  end

  def prepare_connection(selection, missing_entries, credential)
    provider_key = selection.pack.dig('provider', 'key')
    connect_provider!(provider_key: provider_key, credential: credential, required_scopes: required_connection_scopes(selection))
    connection_requirement(provider_key, selection.required_scopes(missing_entries))
  end

  def install_missing_tools!(selection, integration_hook)
    installation.update!(status: 'validating', integration_hook: integration_hook)

    account.with_lock do
      existing_by_key = installed_tools(selection).index_by(&:template_key)
      missing_entries = selection.items.reject { |entry| existing_by_key.key?(entry.dig(:template, 'key')) }
      validate_capacity_without_lock!(missing_entries.length)
      installation.update!(status: 'installing')

      missing_entries.each do |entry|
        tool = account.captain_custom_tools.create!(
          Captain::ToolCatalog::SnapshotBuilder.new(pack: selection.pack, entry: entry, integration_hook: integration_hook).attributes
        )
        existing_by_key[tool.template_key] = tool
      end

      complete!(tools_in_selection_order(selection, existing_by_key), integration_hook: integration_hook)
    end
  end

  def installed_tools(selection)
    keys = selection.items.map { |entry| entry.dig(:template, 'key') }
    account.captain_custom_tools.catalog.where(provider_key: selection.pack.dig('provider', 'key'), template_key: keys).to_a
  end

  def required_connection_scopes(selection)
    installed_scopes = account.captain_custom_tools.catalog.where(provider_key: selection.pack.dig('provider', 'key')).flat_map do |tool|
      tool.definition.fetch('operations').flat_map { |operation| operation.fetch('scopes') }
    end
    (selection.required_scopes + installed_scopes).uniq.sort
  end

  def tools_in_selection_order(selection, tools_by_key)
    selection.items.map { |entry| tools_by_key.fetch(entry.dig(:template, 'key')) }
  end

  def validate_capacity!(missing_count)
    account.with_lock { validate_capacity_without_lock!(missing_count) }
  end

  def validate_capacity_without_lock!(missing_count)
    limit = Captain::CustomTool.limit_for(account)
    return if account.captain_custom_tools.count + missing_count <= limit

    raise Captain::ToolCatalog::WorkflowError, 'tool_capacity_exceeded'
  end

  def common_hook(tools_by_key)
    hook_ids = tools_by_key.values.filter_map(&:integration_hook_id).uniq
    account.hooks.find_by(id: hook_ids.first) if hook_ids.one?
  end
end
