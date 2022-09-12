class Public::Api::V1::Portals::ArticlesController < PublicController
  before_action :ensure_custom_domain_request, only: [:show, :index]
  before_action :set_portal
  before_action :set_category
  before_action :set_article, only: [:show]

  def index
    @articles = @portal.articles
    @articles = @articles.search(list_params) if list_params.present?
  end

  def show; end

  private

  def set_article
    @article = @category.articles.find(params[:id])
  end

  def set_category
    @category = @portal.categories.find_by!(slug: params[:category_slug])
  end

  def set_portal
    @portal = @portals.find_by!(slug: params[:slug], archived: false)
  end

  def list_params
    params.permit(:query)
  end
end
