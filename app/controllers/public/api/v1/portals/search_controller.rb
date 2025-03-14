class Public::Api::V1::Portals::SearchController < Public::Api::V1::Portals::BaseController
  before_action :portal
  layout 'portal'

  def index
    @query = params[:query]
    @articles = @portal.articles.published

    @articles = @articles.search(search_params) if @query.present?

    @articles = @articles.page(params[:page]).per(10) # Add pagination
  end

  private

  def search_params
    params.permit(:query, :locale, :sort, :status, :page)
  end
end
