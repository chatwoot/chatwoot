class Captain::ToolCatalog::CatalogQuery
  DISPLAY_NAME_SETTING_KEYS = %w[display_name external_name account_name store_name workspace_name team_name channel_name].freeze

  def initialize(account:, registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @account = account
    @registry = registry
  end

  def summaries
    {
      payload: packs.map { |pack| provider_summary(pack) },
      meta: { capacity: capacity }
    }
  end

  def provider(provider_key)
    pack = registry.find(provider_key)

    {
      payload: provider_details(pack),
      meta: { capacity: capacity }
    }
  end

  private

  attr_reader :account, :registry

  def packs
    @packs ||= registry.all
  end

  def provider_summary(pack)
    provider = pack.fetch('provider')
    templates = pack.fetch('templates')
    provider_key = provider.fetch('key')
    installed_tools = installed_tools_by_provider.fetch(provider_key, [])

    provider.merge(
      'category_count' => pack.fetch('categories').length,
      'available_template_count' => templates.count { |template| template.fetch('availability') == 'available' },
      'template_count' => templates.length,
      'availability_counts' => templates.map { |template| template.fetch('availability') }.tally,
      'installed_count' => installed_tools.length,
      'update_count' => update_count(templates, installed_tools),
      'connection' => connection_for(provider_key)
    )
  end

  def update_count(templates, installed_tools)
    template_versions = templates.to_h { |template| [template.fetch('key'), template.fetch('version')] }
    installed_tools.count do |tool|
      template_versions[tool.template_key].present? && template_versions[tool.template_key] != tool.template_version
    end
  end

  def provider_details(pack)
    provider = pack.fetch('provider')
    provider_key = provider.fetch('key')
    installed_by_template = installed_tools_by_provider.fetch(provider_key, []).index_by(&:template_key)

    provider.merge(
      'authentication_strategy' => pack.dig('authentication', 'strategy'),
      'connection' => connection_for(provider_key),
      'installed_count' => installed_by_template.length,
      'categories' => categories(pack, installed_by_template)
    )
  end

  def categories(pack, installed_by_template)
    templates_by_category = pack.fetch('templates').group_by { |template| template.fetch('category_key') }

    pack.fetch('categories').map do |category|
      category.merge(
        'templates' => templates_by_category.fetch(category.fetch('key'), []).map do |template|
          template_details(template, installed_by_template[template.fetch('key')])
        end
      )
    end
  end

  def template_details(template, installed_tool)
    template.slice('key', 'version', 'name', 'description', 'availability', 'risk_class', 'model_visible', 'configuration_schema').merge(
      'required_scopes' => template.fetch('effective_scopes'),
      'operation_keys' => template.fetch('recipe').pluck('operation_key'),
      'installed' => installed_tool.present?,
      'installed_tool_id' => installed_tool&.id,
      'installed_version' => installed_tool&.template_version,
      'installed_configuration' => installed_tool&.configuration || {},
      'update_available' => installed_tool.present? && installed_tool.template_version != template.fetch('version')
    )
  end

  def installed_tools_by_provider
    @installed_tools_by_provider ||= account.captain_custom_tools.catalog.where(provider_key: provider_keys).to_a.group_by(&:provider_key)
  end

  def hooks_by_provider
    @hooks_by_provider ||= account.hooks.account_hooks.where(app_id: provider_keys).to_a.index_by(&:app_id)
  end

  def provider_keys
    @provider_keys ||= packs.map { |pack| pack.dig('provider', 'key') }
  end

  def connection_for(provider_key)
    hook = hooks_by_provider[provider_key]
    connected = Captain::ToolCatalog::ConnectionStatus.connected?(hook)

    {
      'connected' => connected,
      'status' => connected ? 'enabled' : hook&.status || 'disconnected',
      'display_name' => connection_display_name(hook, provider_key),
      'granted_scopes' => granted_scopes(hook),
      'credential_storage' => Chatwoot.encryption_configured? ? 'encrypted' : 'plaintext'
    }
  end

  def connection_display_name(hook, provider_key)
    return if hook.blank?

    settings = hook.settings.to_h.with_indifferent_access
    display_name = DISPLAY_NAME_SETTING_KEYS.filter_map { |key| settings[key].presence }.first
    display_name || (hook.reference_id if provider_key == 'shopify')
  end

  def granted_scopes(hook)
    return [] if hook.blank?

    settings = hook.settings.to_h.with_indifferent_access
    value = settings[:scopes].presence || settings[:scope]
    scopes = value.is_a?(String) ? value.split(/[\s,]+/) : Array(value)
    scopes.filter_map { |scope| scope.to_s.presence }.uniq.sort
  end

  def capacity
    {
      used: account.captain_custom_tools.count,
      limit: Captain::CustomTool.limit_for(account)
    }
  end
end
