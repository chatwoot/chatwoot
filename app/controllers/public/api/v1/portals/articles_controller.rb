class Public::Api::V1::Portals::ArticlesController < PublicController
  before_action :ensure_custom_domain_request, only: [:show, :index]
  before_action :portal
  before_action :set_category
  before_action :set_article, only: [:show]
  layout 'portal'

  def index
    @articles = @portal.articles
    @articles = @articles.search(list_params) if list_params.present?
  end

  def show; end

  private

  def set_article
    @article = @category.articles.find(params[:id])
    @parsed_content = render_article_content(@article.content)
  end

  def set_category
    @category = @portal.categories.find_by!(slug: params[:category_slug])
  end

  def portal
    @portal ||= Portal.find_by!(slug: params[:slug], archived: false)
  end

  def list_params
    params.permit(:query)
  end

  def render_article_content(content)
    # rubocop:disable Rails/OutputSafety
    CommonMarker.render_html(content).html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
