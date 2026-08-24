class Api::V1::Accounts::Captain::ToolCatalogController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :ensure_tool_catalog_enabled

  def index
    render json: catalog_query.summaries
  end

  def show
    render json: catalog_query.provider(params[:provider_key])
  end

  private

  def catalog_query
    @catalog_query ||= Captain::ToolCatalog::CatalogQuery.new(account: Current.account)
  end

  def ensure_tool_catalog_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?('captain_tool_catalog')
  end
end
