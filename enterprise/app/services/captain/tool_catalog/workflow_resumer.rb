class Captain::ToolCatalog::WorkflowResumer
  WORKFLOWS = {
    'install' => Captain::ToolCatalog::InstallationWorkflow,
    'update' => Captain::ToolCatalog::UpdateWorkflow,
    'reconnect' => Captain::ToolCatalog::ReconnectWorkflow,
    'connect' => Captain::ToolCatalog::ConnectionWorkflow
  }.freeze

  def initialize(registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @registry = registry
  end

  def perform(installation)
    workflow_class = WORKFLOWS.fetch(installation.workflow_kind)
    workflow_class.new(
      account: installation.account,
      initiated_by: installation.initiated_by,
      registry: registry
    ).resume(installation)
  end

  private

  attr_reader :registry
end
