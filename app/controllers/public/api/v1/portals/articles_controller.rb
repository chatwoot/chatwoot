class Public::Api::V1::Portals::ArticlesController < Public::Api::V1::Portals::BaseController
  before_action :ensure_custom_domain_request, only: [:show, :index]
  before_action :portal
  before_action :set_category, except: [:index]
  before_action :set_article, only: [:show]
  layout 'portal'

  def index
    @articles = @portal.articles
    @articles = @articles.search(list_params) if list_params.present?
    @articles.order(position: :asc)
  end

  def show; end

  private

  def set_article
    @article = @category.articles.find(permitted_params[:id])
    @article.increment_view_count
    @parsed_content = render_article_content(@article.content)
  end

  def set_category
    return if permitted_params[:category_slug].blank?

    @category = @portal.categories.find_by!(
      slug: permitted_params[:category_slug],
      locale: permitted_params[:locale]
    )
  end

  def portal
    @portal ||= Portal.find_by!(slug: permitted_params[:slug], archived: false)
  end

  def list_params
    params.permit(:query, :locale)
  end

  def permitted_params
    params.permit(:slug, :category_slug, :locale, :id)
  end

  def render_article_content(content)
    # rubocop:disable Rails/OutputSafety
    CommonMarker.render_html(content).html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
