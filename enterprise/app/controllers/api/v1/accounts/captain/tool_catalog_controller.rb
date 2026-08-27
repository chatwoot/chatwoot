class Api::V1::Accounts::Captain::ToolCatalogController < Api::V1::Accounts::Captain::ToolCatalogBaseController
  def index
    render json: catalog_query.summaries
  end

  def show
    render json: catalog_query.provider(params[:provider_key])
  end

  def reconnect
    installation = Captain::ToolCatalog::ReconnectWorkflow.new(
      account: Current.account,
      initiated_by: Current.user
    ).perform(
      provider_key: params[:provider_key],
      credential: reconnect_params[:credential],
      force_reauthorization: reconnect_params[:force_reauthorization]
    )
    render_installation(installation, status: :created)
  end

  def disconnect
    Captain::ToolCatalog::ConnectionRevoker.new(account: Current.account).perform(provider_key: params[:provider_key])
    head :no_content
  end

  def update
    installation = Captain::ToolCatalog::UpdateWorkflow.new(
      account: Current.account,
      initiated_by: Current.user
    ).perform(provider_key: params[:provider_key], templates: update_params[:templates])
    render_installation(installation, status: :created)
  end

  private

  def catalog_query
    @catalog_query ||= Captain::ToolCatalog::CatalogQuery.new(account: Current.account)
  end

  def update_params
    params.require(:update).permit(
      templates: [:template_key, :template_version, { configuration: {} }]
    )
  end

  def reconnect_params
    return {} if params[:reconnect].blank?

    params.require(:reconnect).permit(:credential, :force_reauthorization)
  end
end
