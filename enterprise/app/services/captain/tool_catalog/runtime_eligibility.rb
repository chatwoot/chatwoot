class Captain::ToolCatalog::RuntimeEligibility
  def initialize(custom_tool)
    @custom_tool = custom_tool
  end

  def eligible?
    ensure!
    true
  rescue Captain::ToolCatalog::ExecutionError
    false
  end

  def ensure!
    validate_catalog_access!
    hook = connected_hook!
    validate_credential!(hook)
    validate_scopes!(hook)
  end

  private

  attr_reader :custom_tool

  def validate_catalog_access!
    raise execution_error('authorization', 'catalog_unavailable') unless custom_tool.account.feature_enabled?('captain_tool_catalog')
    raise execution_error('authorization', 'tool_approval_required') if custom_tool.risk_approval_required?
  end

  def connected_hook!
    hook = custom_tool.integration_hook
    connected = hook.present? && hook.enabled? && hook.account_id == custom_tool.account_id && hook.app_id == custom_tool.provider_key
    raise execution_error('disconnected', 'provider_reconnect_required') unless connected

    hook
  end

  def validate_credential!(hook)
    raise execution_error('authentication', 'provider_credential_missing') if hook.access_token.blank?
  end

  def validate_scopes!(hook)
    raise execution_error('authorization', 'provider_scope_missing') if missing_scopes(hook).any?
  end

  def missing_scopes(hook)
    required_scopes - granted_scopes(hook)
  end

  def required_scopes
    custom_tool.definition.fetch('operations').flat_map { |operation| operation.fetch('scopes') }.uniq
  end

  def granted_scopes(hook)
    settings = hook.settings.to_h.with_indifferent_access
    value = settings[:scopes].presence || settings[:scope]
    scopes = value.is_a?(String) ? value.split(/[\s,]+/) : Array(value)
    scopes.filter_map { |scope| scope.to_s.presence }.uniq
  end

  def execution_error(category, code)
    Captain::ToolCatalog::ExecutionError.new(category, code)
  end
end
