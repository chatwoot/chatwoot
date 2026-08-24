class Api::V1::Accounts::Captain::ToolCatalogConnectionsController < Api::V1::Accounts::Captain::ToolCatalogBaseController
  def create
    installation = Captain::ToolCatalog::ConnectionWorkflow.new(
      account: Current.account,
      initiated_by: Current.user
    ).perform(
      provider_key: connection_params[:provider_key],
      templates: connection_params[:templates]
    )
    render_installation(installation, status: :created)
  end

  private

  def connection_params
    params.require(:connection).permit(
      :provider_key,
      templates: [:template_key, :template_version]
    )
  end
end
