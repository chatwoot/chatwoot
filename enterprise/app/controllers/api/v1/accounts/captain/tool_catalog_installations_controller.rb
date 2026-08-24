class Api::V1::Accounts::Captain::ToolCatalogInstallationsController < Api::V1::Accounts::Captain::ToolCatalogBaseController
  def show
    installation = Current.account.captain_tool_catalog_installations.find(params[:id])
    render_installation(installation)
  end

  def create
    installation = Captain::ToolCatalog::InstallationWorkflow.new(
      account: Current.account,
      initiated_by: Current.user
    ).perform(
      provider_key: installation_params[:provider_key],
      templates: installation_params[:templates]
    )
    render_installation(installation, status: :created)
  end

  private

  def installation_params
    params.require(:installation).permit(
      :provider_key,
      templates: [:template_key, :template_version, { configuration: {} }]
    )
  end
end
