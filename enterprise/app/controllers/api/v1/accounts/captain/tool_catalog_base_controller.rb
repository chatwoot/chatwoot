class Api::V1::Accounts::Captain::ToolCatalogBaseController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :ensure_tool_catalog_enabled

  rescue_from Captain::ToolCatalog::WorkflowError, with: :render_workflow_error

  private

  def ensure_tool_catalog_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?('captain_tool_catalog')
  end

  def render_workflow_error(error)
    render json: { error: { code: error.code } }, status: :unprocessable_entity
  end

  def render_installation(installation, status: :ok)
    render json: Captain::ToolCatalog::InstallationPresenter.new(installation: installation).as_json, status: status
  end
end
