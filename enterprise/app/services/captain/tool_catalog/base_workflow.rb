class Captain::ToolCatalog::BaseWorkflow
  SESSION_TTL = 30.minutes

  def initialize(account:, initiated_by:, registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @account = account
    @initiated_by = initiated_by
    @registry = registry
  end

  protected

  attr_reader :account, :initiated_by, :registry, :installation

  def resolve_selection(provider_key, templates)
    Captain::ToolCatalog::TemplateSelection.new(registry: registry).resolve(
      provider_key: provider_key,
      templates: templates
    )
  end

  def create_installation!(workflow_kind:, provider_key:, selected_templates:)
    @installation = account.captain_tool_catalog_installations.create!(
      initiated_by: initiated_by,
      provider_key: provider_key,
      selected_templates: selected_templates,
      workflow_kind: workflow_kind,
      expires_at: SESSION_TTL.from_now
    )
  end

  def resume_installation!(installation)
    @installation = installation
    installation.expire_if_needed!
    raise Captain::ToolCatalog::WorkflowError, 'installation_expired' if installation.expired?
    return installation if installation.completed?

    installation.update!(status: 'pending', error_code: nil, completed_at: nil, resulting_tool_ids: [])
    installation
  end

  def connection_requirement(provider_key, required_scopes)
    Captain::ToolCatalog::ConnectionRequirement.new(account: account).check(
      provider_key: provider_key,
      required_scopes: required_scopes
    )
  end

  def require_encryption!
    return if Chatwoot.encryption_configured?

    raise Captain::ToolCatalog::WorkflowError, 'encryption_required'
  end

  def connect_provider!(provider_key:, credential:, required_scopes:)
    return if credential.nil?
    raise Captain::ToolCatalog::WorkflowError, 'credential_not_supported' unless provider_key == 'stripe'

    Captain::ToolCatalog::StripeConnection.new(account: account).connect!(
      credential: credential,
      required_scopes: required_scopes
    )
  end

  def await_connection!(requirement)
    installation.update!(
      status: 'awaiting_connection',
      integration_hook: requirement.hook,
      error_code: nil
    )
    installation
  end

  def complete!(tools, integration_hook: nil)
    installation.update!(
      status: 'completed',
      integration_hook: integration_hook,
      resulting_tool_ids: tools.map(&:id),
      error_code: nil,
      completed_at: Time.current
    )
    installation
  end

  def track_failure
    yield
  rescue Captain::ToolCatalog::WorkflowError => e
    mark_failed(e.code)
    raise
  rescue StandardError
    mark_failed('workflow_failed')
    raise
  end

  def mark_failed(error_code)
    return if installation.blank? || installation.completed? || installation.expired?

    installation.update!(status: 'failed', error_code: error_code, completed_at: nil, resulting_tool_ids: [])
  end
end
