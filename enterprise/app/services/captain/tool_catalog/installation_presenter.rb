class Captain::ToolCatalog::InstallationPresenter
  def initialize(installation:, registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @installation = installation
    @registry = registry
  end

  def as_json
    installation.expire_if_needed!
    requirement, catalog_changed = connection_state

    {
      payload: {
        id: installation.id,
        provider_key: installation.provider_key,
        workflow_kind: installation.workflow_kind,
        status: installation.status,
        selected_templates: installation.selected_templates,
        resulting_tool_ids: installation.resulting_tool_ids,
        error_code: installation.error_code,
        expires_at: installation.expires_at.iso8601,
        completed_at: installation.completed_at&.iso8601,
        catalog_changed: catalog_changed,
        connection: connection_payload(requirement)
      }
    }
  end

  private

  attr_reader :installation, :registry

  def connection_state
    scopes, catalog_changed = required_scopes
    requirement = Captain::ToolCatalog::ConnectionRequirement.new(account: installation.account).check(
      provider_key: installation.provider_key,
      required_scopes: scopes
    )
    [requirement, catalog_changed]
  end

  def required_scopes
    return [reconnect_scopes, false] if installation.workflow_reconnect?

    selection = Captain::ToolCatalog::TemplateSelection.new(registry: registry).resolve(
      provider_key: installation.provider_key,
      templates: installation.selected_templates
    )
    selected_items = installation.workflow_install? ? missing_install_items(selection) : selection.items
    [selection.required_scopes(selected_items), false]
  rescue Captain::ToolCatalog::WorkflowError, ActiveRecord::RecordNotFound
    [[], true]
  end

  def missing_install_items(selection)
    installed_keys = installation.account.captain_custom_tools.catalog.where(
      provider_key: installation.provider_key,
      template_key: selection.items.map { |item| item.dig(:template, 'key') }
    ).pluck(:template_key)
    selection.items.reject { |item| installed_keys.include?(item.dig(:template, 'key')) }
  end

  def reconnect_scopes
    tools = installation.account.captain_custom_tools.catalog.where(id: installation.resulting_tool_ids.presence || selected_tool_ids)
    tools.flat_map do |tool|
      tool.definition.fetch('operations').flat_map { |operation| operation.fetch('scopes') }
    end.uniq.sort
  end

  def selected_tool_ids
    installation.account.captain_custom_tools.catalog.where(
      provider_key: installation.provider_key,
      template_key: installation.selected_templates.pluck('template_key')
    ).pluck(:id)
  end

  def connection_payload(requirement)
    {
      connected: requirement.hook&.enabled? || false,
      status: requirement.hook&.status || 'disconnected',
      missing_scopes: requirement.missing_scopes
    }
  end
end
