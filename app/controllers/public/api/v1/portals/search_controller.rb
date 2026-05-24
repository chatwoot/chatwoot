class Public::Api::V1::Portals::SearchController < Public::Api::V1::Portals::BaseController
  before_action :ensure_custom_domain_request, only: [:index]
  before_action :portal
  layout 'portal'

  def index
    @query = params[:query].to_s.strip
    @articles = @portal.articles.published.where(locale: params[:locale])

    search_articles

    @articles = @articles.page(params[:page]).per(10)
  end

  private

  def search_articles
    @articles = @query.present? ? @articles.search(search_params) : @articles.none
  end

  def search_params
    params.permit(:query, :locale, :sort, :status, :page).tap do |permitted|
      permitted[:query] = @query
    end
  end
end

Public::Api::V1::Portals::SearchController.prepend_mod_with('Public::Api::V1::Portals::SearchController')
