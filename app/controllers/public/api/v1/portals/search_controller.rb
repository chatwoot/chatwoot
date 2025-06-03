class Public::Api::V1::Portals::SearchController < Public::Api::V1::Portals::BaseController
  before_action :portal
  layout 'portal'

  def index
    @query = params[:query]
    @articles = @portal.articles.published

    search_articles

    @articles = @articles.page(params[:page]).per(10) # Add pagination
  end

  private

  def search_articles
    @articles = @articles.search(search_params) if @query.present?
  end

  def search_params
    params.permit(:query, :locale, :sort, :status, :page)
  end
end

Public::Api::V1::Portals::SearchController.prepend_mod_with('Public::Api::V1::Portals::SearchController')
