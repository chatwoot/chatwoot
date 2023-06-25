class Public::Api::V1::Portals::ArticlesController < Public::Api::V1::Portals::BaseController
  before_action :ensure_custom_domain_request, only: [:show, :index, :show_plain]
  before_action :portal
  before_action :set_category, except: [:index, :show, :show_plain]
  before_action :set_article, only: [:show, :show_plain]
  after_action :allow_iframe_requests, only: [:show, :show_plain]
  layout 'portal'

  def index
    @articles = @portal.articles
    @articles = @articles.search(list_params) if list_params.present?
    @articles.order(position: :asc)
  end

  def show; end

  def show_plain
    @article = @portal.articles.find_by(slug: permitted_params[:article_slug])
    @article.increment_view_count
    @parsed_content = render_article_content(@article.content)
    render 'show-plain', layout: 'plain-portal'
  end

  private

  def set_article
    @article = @portal.articles.find_by(slug: permitted_params[:article_slug])
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
    params.permit(:slug, :category_slug, :locale, :id, :article_slug)
  end

  def render_article_content(content)
    ChatwootMarkdownRenderer.new(content).render_article
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end
