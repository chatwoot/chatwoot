class ArticlesFinder
  attr_reader :current_user, :current_account, :params

  ARTICLES_PER_PAGE = 15

  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end


  # Assumption if locale is not present sent all the articles in portal/category

  def perform
    set_locale
    find_all_articles

    {
      articles: articles,
      meta: {
        mine_count: @articles.mine.size,
        archived_count: @articles.archived.size,
        published_count: @articles.published.size,
        draft_count: @articles.draft.size,
        articles_count: @articles.size
      }
    }
  end

  private

  def find_all_articles
  	current_portal
  	@articles = @portal.articles
  end


  def set_locale
    @current_locale = params[:locale] || current_portal.try(:default_locale)
  end

  def current_page
    params[:page] || 1
  end

  def current_portal
  	@portal = Portal.find_by(slug: params[:portal_id])
  end


  def articles
    @articles = @articles.joins(
      :category
    ).search_by_category_slug(
      params[:category_slug]
    ).search_by_category_locale(params[:locale]
    ).search_by_author(params[:author_id]).search_by_status(params[:status])

    records = @articles
    records = @articles.text_search(params[:query]) if params[:query].present?
    records.page(current_page).per(ARTICLES_PER_PAGE)
  end
end
